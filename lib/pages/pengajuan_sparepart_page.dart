import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../config.dart';
import '../services/session_manager.dart';
import 'pengajuan_sparepart_form_page.dart';
import 'det_pengajuan_page.dart';
// [OPSIONAL] Anda bisa import animasi empty state jika sudah ada
// import '../core/widget/empty_data_animation.dart';

class PengajuanHeader {
  final String nomor;
  final String detail;
  PengajuanHeader({required this.nomor, required this.detail});
  factory PengajuanHeader.fromJson(Map<String, dynamic> json) {
    return PengajuanHeader(
      nomor: json['Nomor'] ?? '',
      detail: json['Detail'] ?? '',
    );
  }
}

class PengajuanSparepartPage extends StatefulWidget {
  const PengajuanSparepartPage({super.key});

  @override
  State<PengajuanSparepartPage> createState() => _PengajuanSparepartPageState();
}

class _PengajuanSparepartPageState extends State<PengajuanSparepartPage> {
  late DateTime startDate;
  late DateTime endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String selectedStatus = "ALL";
  bool _isLoading = true;
  String? _errorMessage; // [FIX] Tambahkan state error message

  // [PERBAIKAN 1] Tambahkan Search Controller
  final TextEditingController _searchController = TextEditingController();

  List<PengajuanHeader> _pengajuanItems = [];
  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = now;
    endDate = now;
    _updateDateTextFields();
    _fetchPengajuanList();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _searchController.dispose(); // [PERBAIKAN 2] Dispose controller
    super.dispose();
  }

  Future<Map<String, String>> _getAuthHeaders({bool isPost = false}) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }
    final headers = <String, String>{};
    headers['Authorization'] = 'Bearer $token';
    headers['Accept'] = 'application/json';
    if (isPost) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  void _updateDateTextFields() {
    final format = DateFormat('dd/MM/yyyy');
    _startDateController.text = format.format(startDate);
    _endDateController.text = format.format(endDate);
  }

  Future<void> _fetchPengajuanList() async {
    if (!mounted) return; // Cek mounted
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Bersihkan error lama
    });

    try {
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      // [PERBAIKAN 3] Tambahkan parameter 'search'
      final queryParams = {
        'startDate': formattedStartDate,
        'endDate': formattedEndDate,
        'status': selectedStatus,
        'search': _searchController.text, // <-- Ambil teks dari controller
      };

      final uri = Uri.parse('${Config.baseUrl}/pengajuan')
          .replace(queryParameters: queryParams);

      final headers = await _getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      if (!mounted) return; // Cek mounted setelah await

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final List<dynamic> data = result['data'];
          setState(() {
            _pengajuanItems =
                data.map((item) => PengajuanHeader.fromJson(item)).toList();
          });
        } else {
          throw Exception(result['message']);
        }
      } else {
        if (response.statusCode == 401) {
          throw Exception('Akses ditolak. Sesi Anda mungkin telah berakhir.');
        }
        throw Exception(
            'Gagal terhubung ke server (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        // [FIX] Tampilkan error di UI, jangan hanya di snackbar
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime initial = isStart ? startDate : endDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[600],
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return; // Cek mounted setelah await

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
        _updateDateTextFields();
      });
      _fetchPengajuanList(); // [FIX] Panggil fetch setelah ganti tanggal
    }
  }

  Future<void> _deleteItem(String nomor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content:
            Text('Apakah Anda yakin akan menghapus pengajuan nomor $nomor?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Hapus')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final headers = await _getAuthHeaders(isPost: true);
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/pengajuan/delete'),
        headers: headers,
        body: json.encode({'nomor': nomor}),
      );

      if (!mounted) return;
      final result = json.decode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message']), backgroundColor: Colors.green),
        );
        _fetchPengajuanList();
      } else {
        throw Exception(result['message'] ?? 'Gagal menghapus');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menghapus: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _goToForm({PengajuanHeader? pengajuan}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PengajuanSparepartFormPage(
          nomorPengajuan: pengajuan?.nomor,
        ),
      ),
    );
    if (result == true && mounted) {
      // Cek mounted
      _fetchPengajuanList();
    }
  }

  void _viewDetail(String nomor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetPengajuanPage(nomor: nomor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("List Pengajuan Sparepart",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterSection(), // Widget untuk filter
          Expanded(
            child: _buildContentSection(), // Widget untuk konten
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        onPressed: () => _goToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Dari',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_month),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _endDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Sampai',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_month),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // [PERBAIKAN DI SINI] Bungkus Status dan Search dalam Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                      labelText: "Status",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  items: const [
                    DropdownMenuItem(value: "ALL", child: Text("ALL")),
                    DropdownMenuItem(value: "CLOSE", child: Text("CLOSE")),
                    DropdownMenuItem(value: "PROSES", child: Text("PROSES")),
                    DropdownMenuItem(value: "BELUM", child: Text("BELUM")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedStatus = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari No. Pengajuan...', // Disesuaikan
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onSubmitted: (_) =>
                      _fetchPengajuanList(), // Trigger search on Enter
                ),
              ),
            ],
          ),
          // [AKHIR PERBAIKAN]

          const SizedBox(height: 8), // Beri jarak sebelum tombol "Cari"

          // Tombol "Cari" sekarang ada di barisnya sendiri
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchPengajuanList,
              icon: const Icon(Icons.search),
              label: const Text("Cari"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // [FIX] Tampilkan error jika ada
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_pengajuanItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchPengajuanList,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              alignment: Alignment.center,
              child: const Text('Tidak ada data pengajuan.')),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPengajuanList,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _pengajuanItems.length,
        itemBuilder: (context, index) {
          final item = _pengajuanItems[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(item.nomor,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item.detail,
                  style: const TextStyle(color: Colors.black54)),
              isThreeLine: true,
              onTap: () => _viewDetail(item.nomor),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    _goToForm(pengajuan: item);
                  } else if (value == 'delete') {
                    _deleteItem(item.nomor);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit_note, color: Colors.orange),
                        title: Text('Edit')),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                        leading: Icon(Icons.delete_forever, color: Colors.red),
                        title: Text('Hapus')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
