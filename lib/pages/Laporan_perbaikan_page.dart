import 'dart:convert';
import 'dart:async'; // [FIX] Tambahkan import
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../../config.dart';
import '../services/session_manager.dart';
import '../data/laporan_perbaikan_model.dart';
// [FIX] Impor file animasi (sesuaikan path jika perlu)
import '../core/widget/empty_data_animation.dart';

class LaporanPerbaikanPage extends StatefulWidget {
  const LaporanPerbaikanPage({super.key});

  @override
  State<LaporanPerbaikanPage> createState() => _LaporanPerbaikanPageState();
}

class _LaporanPerbaikanPageState extends State<LaporanPerbaikanPage> {
  // State untuk filter
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedUserId = 'ALL';
  String _selectedBranch = 'ALL';
  String _selectedStatus = 'BELUM_SELESAI';

  // [FIX] Tambahkan controller untuk search dan date
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // State untuk data
  bool _isLoading = true;
  String? _errorMessage;
  List<LaporanPerbaikanItem> _reportItems = [];
  List<UserFilterItem> _userOptions = [];
  List<BranchFilterItem> _branchOptions = [];

  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    _updateDateTextFields(); // Set teks tanggal
    _loadFilterOptions().then((_) => _fetchReports());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // [PERBAIKAN 1] Tambahkan helper otentikasi
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  void _updateDateTextFields() {
    final format = DateFormat('dd/MM/yyyy');
    _startDateController.text = format.format(_startDate);
    _endDateController.text = format.format(_endDate);
  }

  Future<void> _loadFilterOptions() async {
    try {
      // [FIX] Tambahkan header otentikasi
      final headers = await _getAuthHeaders();

      final userUri =
          Uri.parse('${Config.baseUrl}/laporan/filter-options/users');
      final branchUri =
          Uri.parse('${Config.baseUrl}/laporan/filter-options/branches');

      final responses = await Future.wait([
        http.get(userUri, headers: headers), // <-- Kirim headers
        http.get(branchUri, headers: headers), // <-- Kirim headers
      ]);

      if (!mounted) return; // Cek mounted

      List<UserFilterItem> users = [];
      if (responses[0].statusCode == 200) {
        final List<dynamic> userData = json.decode(responses[0].body)['data'];
        users = userData.map((user) => UserFilterItem.fromJson(user)).toList();
      }

      List<BranchFilterItem> branches = [];
      if (responses[1].statusCode == 200) {
        final List<dynamic> branchData = json.decode(responses[1].body)['data'];
        branches = branchData
            .map((branch) => BranchFilterItem.fromJson(branch))
            .toList();
      }

      setState(() {
        _userOptions = users;
        _branchOptions = branches;
      });
    } catch (e) {
      _showError('Gagal memuat opsi filter: ${e.toString()}');
    }
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(_startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(_endDate);

      // [PERBAIKAN 2] Tambahkan 'search' ke query
      final queryParams = {
        'startDate': formattedStartDate,
        'endDate': formattedEndDate,
        'status': _selectedStatus,
        'branch': _selectedBranch,
        'userId': _selectedUserId,
        'search': _searchController.text, // <-- Tambahkan ini
      };

      final uri = Uri.parse('${Config.baseUrl}/laporan/perbaikan')
          .replace(queryParameters: queryParams);

      // [FIX] Tambahkan header otentikasi
      final headers = await _getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (!mounted) return; // Cek mounted

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final List<dynamic> data = result['data'];
          setState(() {
            _reportItems = data
                .map((item) => LaporanPerbaikanItem.fromJson(item))
                .toList();
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
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper functions
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _viewDetail(String nomor) {
    // Navigator.push(context, MaterialPageRoute(builder: (_) => DetailAssetPage(nomor: nomor)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Membuka detail untuk nomor: $nomor')),
    );
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

    if (!mounted) return; // Cek mounted

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _updateDateTextFields(); // Update text field
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Perbaikan",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterPanel(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  // [PERBAIKAN 3] Ganti _buildContent
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      // Tampilkan widget error
      return EmptyDataAnimation(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'Oops, Terjadi Kesalahan',
        message: _errorMessage!,
        onRefresh: _fetchReports,
      );
    }

    if (_reportItems.isEmpty) {
      // Tampilkan widget animasi saat data kosong
      return EmptyDataAnimation(
        icon: Icons.search_off,
        iconColor: Colors.grey[400],
        title: 'Tidak Ada Data Ditemukan',
        message: 'Coba ubah filter atau tanggal Anda.',
        onRefresh: _fetchReports,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _reportItems.length,
        itemBuilder: (context, index) {
          final item = _reportItems[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(item.nomor,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item.detail,
                  style: const TextStyle(color: Colors.black54, height: 1.5)),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blue),
                onPressed: () => _viewDetail(item.nomor),
                tooltip: 'Lihat Detail',
              ),
            ),
          );
        },
      ),
    );
  }

  // [PERBAIKAN 4] Perbarui filter panel
  Widget _buildFilterPanel() {
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
                  decoration: _inputDecoration('Dari')
                      .copyWith(suffixIcon: const Icon(Icons.calendar_month)),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _endDateController,
                  readOnly: true,
                  decoration: _inputDecoration('Sampai')
                      .copyWith(suffixIcon: const Icon(Icons.calendar_month)),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBranch,
                  decoration: _inputDecoration('Cabang'),
                  items: [
                    const DropdownMenuItem(
                        value: 'ALL', child: Text('SEMUA CABANG')),
                    ..._branchOptions.map((branch) => DropdownMenuItem(
                          value: branch.kodeCabang,
                          child: Text(branch.namaCabang,
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedBranch = value ?? 'ALL'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUserId,
                  decoration: _inputDecoration('User Peminta'),
                  items: [
                    const DropdownMenuItem(
                        value: 'ALL', child: Text('SEMUA USER')),
                    ..._userOptions.map((user) => DropdownMenuItem(
                          value: user.userKode,
                          child: Text(user.userNama,
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedUserId = value ?? 'ALL'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: _inputDecoration("Status Pengerjaan"),
            items: const [
              DropdownMenuItem(value: "ALL", child: Text("Semua")),
              DropdownMenuItem(
                  value: "BELUM_SELESAI",
                  child: Text("Belum Selesai (Proses/Belum)")),
              DropdownMenuItem(value: "BELUM", child: Text("Belum Dikerjakan")),
              DropdownMenuItem(
                  value: "PROSES", child: Text("Dalam Pengerjaan")),
              DropdownMenuItem(value: "SELESAI", child: Text("Sudah Selesai")),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedStatus = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: _inputDecoration('Cari No. Job, Lokasi, Ket...')
                .copyWith(prefixIcon: const Icon(Icons.search)),
            onSubmitted: (_) => _fetchReports(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchReports,
              icon: _isLoading
                  ? Container(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.search),
              label: Text(_isLoading ? "Mencari..." : "Cari"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [PERBAIKAN 6] Hapus _buildDatePicker (sudah diganti TextFormField)

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }
}
