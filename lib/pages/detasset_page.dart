import 'dart:async';
import 'dart:convert'; // [FIX] Tambahkan import
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // [FIX] Tambahkan import
import 'package:intl/intl.dart';

// [FIX] Hapus ApiService
// import '../services/api_service.dart';
import '../services/session_manager.dart'; // [FIX] Tambahkan import
import '../data/detasset_model.dart';
import '../core/widget/empty_data_animation.dart';
import 'widget/detasset_list_loading.dart';
import 'perbaikan_page.dart';
import '../../../../config.dart'; // [FIX] Tambahkan config

class DetAssetPage extends StatefulWidget {
  final String? nama;
  final String? divisi;
  final String? cabang;
  final String? userKode;

  const DetAssetPage({
    super.key,
    this.nama,
    this.divisi,
    this.cabang,
    this.userKode,
  });

  @override
  State<DetAssetPage> createState() => _DetAssetPageState();
}

class _DetAssetPageState extends State<DetAssetPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<DetAsset> _assetList = [];
  // [FIX] _filteredList dihapus karena tidak perlu
  // List<DetAsset> _filteredList = [];
  final _searchController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // [PERBAIKAN 1] Sesuaikan _statusOptions dengan backend (detasset.service.js)
  String _selectedStatus = 'ALL';
  String _closeStatus = 'NOT CLOSE';
  final List<String> _statusOptions = ['ALL', 'BELUM', 'PROSES', 'SELESAI'];
  final List<String> _closeStatusOptions = ['NOT CLOSE', 'CLOSE', 'ALL'];

  final SessionManager _sessionManager = SessionManager(); // [FIX] Tambahkan

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final now = DateTime.now();
    _startDate = now;
    _endDate = now;
    _updateDateTextFields();
    await _fetchAssets();
  }

  // [PERBAIKAN 2] Tambahkan helper otentikasi
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _sessionManager.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // [PERBAIKAN 3] Perbarui _fetchAssets
  Future<void> _fetchAssets() async {
    if (!mounted) return; // Cek mounted di awal
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queryParams = <String, String>{};
      if (_startDate != null) {
        queryParams['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
      }
      if (_endDate != null) {
        queryParams['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
      }
      if (_selectedStatus != 'ALL') {
        // Kirim 'BELUM', 'PROSES', atau 'SELESAI'
        queryParams['status'] = _selectedStatus.toUpperCase();
      }
      queryParams['close_status'] = _closeStatus;

      if (_searchController.text.isNotEmpty) {
        queryParams['search'] = _searchController.text;
      }
      if (widget.userKode != null && widget.userKode!.isNotEmpty) {
        queryParams['user_kode'] = widget.userKode!;
      }

      // [FIX] Ganti ApiService.getDetAssetList dengan http.get + token
      final headers = await _getAuthHeaders();
      // Asumsi endpoint ini benar
      final uri = Uri.parse('${Config.baseUrl}/detasset/')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Asumsi backend mengembalikan list JSON langsung
        final List<dynamic> jsonList = json.decode(response.body);
        setState(() {
          _assetList = jsonList.map((item) => DetAsset.fromJson(item)).toList();
        });
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Error Server: ${response.statusCode}');
      }
    } on TimeoutException {
      if (mounted)
        setState(() =>
            _errorMessage = 'Server tidak merespons. Periksa koneksi Anda.');
    } catch (e) {
      if (mounted)
        setState(() => _errorMessage = 'Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateDateTextFields() {
    final format = DateFormat('dd/MM/yyyy');
    if (_startDate != null)
      _startDateController.text = format.format(_startDate!);
    if (_endDate != null) _endDateController.text = format.format(_endDate!);
  }

  Future<void> _pickDate(bool isStartDate) async {
    final initialDate = (isStartDate ? _startDate : _endDate) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      // [FIX] Tambahkan tema biru
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

    if (!mounted) return; // [FIX] Cek mounted

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
        _updateDateTextFields();
      });
      _fetchAssets();
    }
  }

  Future<void> _navigateToPerbaikanPage(DetAsset? asset) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerbaikanPage(
          asset: asset,
          nama: widget.nama,
          divisi: widget.divisi,
          cabang: widget.cabang,
          userKode: widget.userKode,
        ),
      ),
    );

    if (result == true && mounted) {
      // [FIX] Cek mounted
      _fetchAssets();
    }
  }

  Widget _buildInfo(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(':'),
          ),
          Expanded(
            flex: 6,
            child: Text(value ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // [PERBAIKAN 4] Ganti _buildContent
  Widget _buildContent() {
    if (_isLoading) return const DetAssetListLoading();

    if (_errorMessage != null) {
      return EmptyDataAnimation(
          icon: Icons.error_outline,
          iconColor: Colors.red,
          title: 'Terjadi Kesalahan',
          message: _errorMessage!,
          onRefresh: _fetchAssets);
    }

    // [FIX] Cek _assetList, bukan _filteredList
    if (_assetList.isEmpty) {
      return EmptyDataAnimation(
          icon: Icons.search_off,
          iconColor: Colors.grey[400],
          title: 'Tidak Ada Data',
          message: 'Anda belum memiliki pengajuan dengan filter saat ini.',
          onRefresh: _fetchAssets);
    }

    return RefreshIndicator(
      onRefresh: _fetchAssets,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 8),
        itemCount: _assetList.length, // [FIX] Ganti ke _assetList
        itemBuilder: (context, index) {
          final asset = _assetList[index]; // [FIX] Ganti ke _assetList
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              title: Text(
                asset.jbNomor,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfo('Tanggal', asset.tglPengajuan),
                    _buildInfo('Peminta', asset.peminta),
                    _buildInfo('Divisi', asset.divisi),
                    _buildInfo('Bagian', asset.bagian),
                    _buildInfo('Kerusakan', asset.lokasi),
                    _buildInfo('Jenis', asset.jenis),
                    _buildInfo('Kepentingan', asset.status),
                    _buildInfo('Keterangan', asset.keterangan),
                    _buildInfo('Dikonfirmasi GA', asset.konfirGA),
                    _buildInfo('Jadwal Pengerjaan', asset.jadwalPengerjaan),
                    _buildInfo('Teknisi', asset.teknisi),
                    _buildInfo('Selesai', asset.selesai),
                    _buildInfo('Close', asset.close),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueGrey),
                onPressed: () => _navigateToPerbaikanPage(asset),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateFilter() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _startDateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Dari',
              suffixIcon: Icon(Icons.calendar_month),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onTap: () => _pickDate(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _endDateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Sampai',
              suffixIcon: Icon(Icons.calendar_month),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onTap: () => _pickDate(false),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String value, List<String> items, String label,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
            value: item, child: Text(item, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengajuan Saya'),
        backgroundColor: Colors.blue[700], // [FIX] Samakan tema
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                _buildDateFilter(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                          // [FIX] Gunakan _statusOptions yang sudah benar
                          _selectedStatus,
                          _statusOptions,
                          'Status', (value) {
                        if (value == null) return;
                        setState(() => _selectedStatus = value);
                        _fetchAssets();
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                          _closeStatus, _closeStatusOptions, 'Close', (value) {
                        if (value == null) return;
                        setState(() => _closeStatus = value);
                        _fetchAssets();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nomor, lokasi, divisi...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (_) => _fetchAssets(),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToPerbaikanPage(null),
        tooltip: 'Tambah Perbaikan',
        backgroundColor: Colors.blue[700], // [FIX] Samakan tema
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
