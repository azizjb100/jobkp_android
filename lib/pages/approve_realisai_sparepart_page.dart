import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../config.dart'; // Sesuaikan path ke config Anda
import '../services/session_manager.dart'; // Sesuaikan path ke session manager

class ApproveRealisasiSparepartPage extends StatefulWidget {
  const ApproveRealisasiSparepartPage({super.key});

  @override
  State<ApproveRealisasiSparepartPage> createState() =>
      _ApproveRealisasiSparepartPageState();
}

class _ApproveRealisasiSparepartPageState
    extends State<ApproveRealisasiSparepartPage> {
  // --- State UI ---
  bool _isLoading = true;
  bool _isDetailView = false; // Menggantikan TTabControl
  String? _errorMessage;

  // --- State Data ---
  List<dynamic> _realisasiList = []; // Untuk lbData
  List<dynamic> _detailList = []; // Untuk lbData2
  String? _selectedNomor; // Nomor yang sedang dilihat detailnya

  // --- State Filter ---
  late DateTime _startDate;
  late DateTime _endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String _selectedStatus = 'PENDING'; // Default "Not Approve" (rbNotApprove)

  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    // Set tanggal default ke awal dan akhir bulan (sesuai FormCreate Delphi)
    final now = DateTime.now();
    // _startDate = DateTime(now.year, now.month, 1);
    // _endDate = DateTime(now.year, now.month + 1, 0);
    _startDate = now;
    _endDate = now;
    _updateDateTextFields();
    _fetchList(); // Langsung muat data (seperti FormShow)
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // --- Helper Otentikasi ---
  Future<Map<String, String>> _getAuthHeaders({bool isPost = false}) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
    if (isPost) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  // --- Helper Tampilan ---
  void _updateDateTextFields() {
    final format = DateFormat('dd/MM/yyyy');
    _startDateController.text = format.format(_startDate);
    _endDateController.text = format.format(_endDate);
  }

  // --- Logika API (dari Delphi) ---

  /**
   * Mengambil daftar realisasi (Header)
   * (Sama seperti imgrefreshClick)
   */
  Future<void> _fetchList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final headers = await _getAuthHeaders();
      final uri =
          Uri.parse('${Config.baseUrl}/realisasi').replace(queryParameters: {
        'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(_endDate),
        'status': _selectedStatus, // 'PENDING' atau 'APPROVED'
      });

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        setState(() {
          _realisasiList = json.decode(response.body);
        });
      } else if (response.statusCode == 401) {
        throw Exception('Akses ditolak. Sesi Anda mungkin telah berakhir.');
      } else {
        throw Exception('Gagal memuat data. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /**
   * Mengambil detail item sparepart
   * (Sama seperti fndetail)
   */
  Future<void> _fetchDetails(String nomor) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedNomor = nomor;
    });
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${Config.baseUrl}/realisasi/$nomor');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          _detailList = json.decode(response.body);
          _isDetailView = true; // Pindah ke TabDetail
        });
      } else {
        if (response.statusCode == 401) {
          throw Exception('Akses ditolak. Sesi Anda mungkin telah berakhir.');
        }
        throw Exception('Gagal memuat detail. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /**
   * Mengirim persetujuan
   * (Sama seperti fnapprove)
   */
  Future<void> _approveRealisasi(String nomor) async {
    // Tampilkan dialog konfirmasi (MessageDlg)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content:
            const Text('Apakah Anda yakin akan meng-approve realisasi ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Approve')),
        ],
      ),
    );

    if (confirm != true) return;

    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final headers = await _getAuthHeaders(isPost: true);
      // Backend akan mengambil nama user dari token
      final uri = Uri.parse('${Config.baseUrl}/realisasi/$nomor/approve');

      final response = await http.post(uri, headers: headers);
      Navigator.pop(context); // Tutup loading

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Sukses diapprove!'),
            backgroundColor: Colors.green,
          ),
        );
        _goBackToList(); // Kembali ke list dan refresh
      } else {
        if (response.statusCode == 401) {
          throw Exception('Akses ditolak. Sesi Anda mungkin telah berakhir.');
        }
        final result = json.decode(response.body);
        throw Exception(result['message'] ??
            'Gagal approve. Status: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // Tutup loading jika error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  /**
   * Kembali ke TabNomor
   * (Sama seperti imgbackClick)
   */
  void _goBackToList() {
    setState(() {
      _isDetailView = false;
      _selectedNomor = null;
      _detailList = [];
    });
    _fetchList(); // Refresh list setelah kembali
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime initial = isStart ? _startDate : _endDate;

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

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _updateDateTextFields(); // Update text field
      });
      _fetchList(); // Langsung refresh saat tanggal diubah
    }
  }

  // --- Bagian UI (Build Methods) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filter section HANYA tampil jika di list view
          if (!_isDetailView) _buildFilterSection(),

          // Content section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isDetailView
                    ? _buildDetailView()
                    : _buildListView(),
          ),
        ],
      ),
    );
  }

  /**
   * Membuat AppBar yang dinamis
   * (Mirip logika TTabControl)
   */
  AppBar _buildAppBar() {
    if (_isDetailView) {
      // AppBar untuk TabDetail
      return AppBar(
        title: Text(_selectedNomor ?? 'Detail Realisasi'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToList, // Panggil fungsi back
        ),
      );
    } else {
      // AppBar untuk TabNomor
      return AppBar(
        title: const Text('Approve Realisasi Sparepart'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      );
    }
  }

  /**
   * Tampilan untuk TabNomor
   */
  Widget _buildListView() {
    if (_errorMessage != null) {
      return Center(
          child:
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_realisasiList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchList,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              alignment: Alignment.center,
              child: const Text('Tidak ada data untuk filter ini.')),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchList,
      child: ListView.builder(
        itemCount: _realisasiList.length,
        itemBuilder: (context, index) {
          final item = _realisasiList[index];
          return _buildRealisasiCard(item);
        },
      ),
    );
  }

  /**
   * Tampilan untuk TabDetail
   */
  Widget _buildDetailView() {
    if (_errorMessage != null) {
      return Center(
          child:
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_detailList.isEmpty) {
      return const Center(
          child: Text('Tidak ada item detail untuk realisasi ini.'));
    }

    // Tampilan ini meniru lbData2 dan locustomdata2
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _detailList.length,
      itemBuilder: (context, index) {
        final item = _detailList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text((index + 1).toString()),
            ),
            title: Text(item['nama'] ?? 'Tanpa Nama'),
            subtitle: Text('Kode: ${item['kode']} | Satuan: ${item['satuan']}'),
            trailing: Text(
              'Qty: ${item['qty']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  /**
   * Widget untuk Filter (Tanggal & Status)
   */
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
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
                    suffixIcon: Icon(Icons.calendar_month),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _endDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Sampai',
                    suffixIcon: Icon(Icons.calendar_month),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ini menggantikan TRadioButton
          SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              selectedBackgroundColor: Colors.blue[600],
              selectedForegroundColor: Colors.white,
            ),
            segments: const [
              ButtonSegment(
                value: 'PENDING',
                label: Text('Belum Approve'),
                icon: Icon(Icons.hourglass_top),
              ),
              ButtonSegment(
                value: 'APPROVED',
                label: Text('Sudah Approve'),
                icon: Icon(Icons.check_circle),
              ),
            ],
            selected: {_selectedStatus},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedStatus = newSelection.first;
              });
              _fetchList(); // Langsung refresh saat status diubah
            },
          ),
        ],
      ),
    );
  }

  /**
   * Widget untuk satu item di daftar realisasi
   * (Mirip locustomdata)
   */
  Widget _buildRealisasiCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['nomor'],
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue),
            ),
            const Divider(),
            _buildInfoRow('Tanggal', item['tanggal']),
            _buildInfoRow('Pengajuan', item['pengajuan']),
            _buildInfoRow('Peminta', item['peminta']),
            _buildInfoRow('Di-approve oleh', item['apv'] ?? '-'),
            _buildInfoRow('Tgl Approve', item['dtapv'] ?? '-'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tombol Detail (fndetail)
                TextButton.icon(
                  icon: const Icon(Icons.list_alt, size: 20),
                  label: const Text('Detail'),
                  onPressed: () => _fetchDetails(item['nomor']),
                ),
                const SizedBox(width: 8),
                // Tombol Approve (fnapprove) - hanya tampil jika 'PENDING'
                if (_selectedStatus == 'PENDING')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _approveRealisasi(item['nomor']),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          const Text(': '),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
