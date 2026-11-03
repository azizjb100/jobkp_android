import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../data/jobit_model.dart';
import '../services/session_manager.dart';
import 'jobit_form_page.dart';
import 'jobit_det_page.dart';
import '../core/widget/empty_data_animation.dart';
import '../../../../config.dart';

class JobItPage extends StatefulWidget {
  const JobItPage({super.key});

  @override
  State<JobItPage> createState() => _JobItPageState();
}

class _JobItPageState extends State<JobItPage> {
  final SessionManager _sessionManager = SessionManager();
  bool _isLoading = true;
  String? _error;
  List<ItJob> _jobList = [];
  int? _selectedIndex;

  // State Filter
  final TextEditingController searchController = TextEditingController();
  late DateTime startDate;
  late DateTime endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String selectedCabang = 'ALL';
  String selectedIT = 'ALL';
  String selectedStatus = 'ALL';

  final List<String> _cabangList = ['ALL', 'P01', 'P02', 'P03', 'P04', 'P05'];
  List<String> _itList = ['ALL'];

  // Data User (dari session)
  bool _isItAdmin = false;
  String? _userKode;
  String? _userCabang;
  String? _userNama;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1); // Awal bulan
    endDate = DateTime(now.year, now.month + 1, 0); // Akhir bulan
    _updateDateTextFields();

    _loadInitialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getAuthHeaders(
      {bool isPostOrDelete = false}) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
    if (isPostOrDelete) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  void _updateDateTextFields() {
    final format = DateFormat('dd/MM/yy');
    _startDateController.text = format.format(startDate);
    _endDateController.text = format.format(endDate);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await _sessionManager.getUserData();
      if (!mounted) return;

      _userKode = user['user_kode'];
      _userCabang = user['cabang'];
      _userNama = user['nama'];
      _isItAdmin = (user['it']?.toString() ?? '0') == '1';

      if (_isItAdmin) {
        final headers = await _getAuthHeaders();
        final itStaffUri = Uri.parse('${Config.baseUrl}/jobit/it-staff');
        final response = await http.get(itStaffUri, headers: headers);

        if (!mounted) return;
        if (response.statusCode == 200) {
          final List<dynamic> itStaffData = json.decode(response.body);
          setState(() {
            _itList = ['ALL', ...List<String>.from(itStaffData)];
          });
        } else {
          debugPrint("Gagal load IT Staff");
        }
      } else {
        setState(() {
          selectedCabang = _userCabang ?? 'ALL';
        });
      }

      await _fetchJobs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchJobs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String statusApiValue = 'ALL';
      if (selectedStatus == 'Belum') statusApiValue = '0';
      if (selectedStatus == 'Selesai') statusApiValue = '1';
      if (selectedStatus == 'Proses') statusApiValue = '2';

      final filters = <String, String>{
        'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(endDate),
        'cabang': selectedCabang,
        'it_staff': selectedIT,
        'status': statusApiValue,
        'search': searchController.text,
      };

      if (!_isItAdmin) {
        filters['user_kode'] = _userKode ?? '';
      }

      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${Config.baseUrl}/jobit/jobs')
          .replace(queryParameters: filters);
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _jobList = data.map((json) => ItJob.fromJson(json)).toList();
          _selectedIndex = null;
        });
      } else {
        if (response.statusCode == 401 || response.statusCode == 403) {
          setState(() {
            _jobList = [];
            _error = null;
          });
        } else {
          final errorBody = json.decode(response.body);
          throw Exception(errorBody['message'] ??
              'Gagal memuat jobs. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text('LIST JOB IT'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isItAdmin) _buildFilterSection(),
            if (_isItAdmin) _buildSearchBox(),
            if (_isItAdmin) const Divider(height: 1, color: Colors.grey),
            Expanded(child: _buildJobList()),
            _buildBottomBar(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isItAdmin ? _fetchJobs : _onNewPressed,
        tooltip: _isItAdmin ? "Refresh" : "Tambah Job",
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        child: Icon(_isItAdmin ? Icons.refresh : Icons.add),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startDateController,
                  readOnly: true,
                  decoration: _inputDecoration("Dari").copyWith(
                    suffixIcon: const Icon(Icons.calendar_today,
                        size: 18, color: Colors.blue),
                  ),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _endDateController,
                  readOnly: true,
                  decoration: _inputDecoration("Sampai").copyWith(
                    suffixIcon: const Icon(Icons.calendar_today,
                        size: 18, color: Colors.blue),
                  ),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: "Cabang:",
                  value: selectedCabang,
                  items: _cabangList,
                  onChanged: _isItAdmin
                      ? (val) {
                          setState(() => selectedCabang = val!);
                          _fetchJobs();
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  label: "IT:",
                  value: selectedIT,
                  items: _itList,
                  onChanged: _isItAdmin
                      ? (val) {
                          setState(() => selectedIT = val!);
                          _fetchJobs();
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRadioStatus('ALL'),
              _buildRadioStatus('Belum'),
              _buildRadioStatus('Proses'),
              _buildRadioStatus('Selesai'),
            ],
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade400)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade400)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    final currentValue = items.contains(value) ? value : items.first;
    final bool isEnabled = onChanged != null;

    return Row(
      children: [
        Text(label),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isEnabled ? Colors.white : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
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

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
        _updateDateTextFields();
      });
      _fetchJobs();
    }
  }

  Widget _buildRadioStatus(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: label,
          groupValue: selectedStatus,
          onChanged: (val) {
            setState(() => selectedStatus = val!);
            _fetchJobs();
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        Text(label),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: TextField(
        controller: searchController,
        onSubmitted: (_) => _fetchJobs(),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: "Cari Nomor, Lokasi, atau Divisi...",
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildJobList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return EmptyDataAnimation(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'Oops, Terjadi Kesalahan',
        message: _error!,
        onRefresh: _fetchJobs,
      );
    }

    if (!_isItAdmin && _jobList.isEmpty) {
      return EmptyDataAnimation(
        icon: Icons.add_task_rounded,
        iconColor: Colors.blue[700],
        title: 'Mode Input',
        message: 'Gunakan tombol (+) di kanan bawah untuk menambah job baru.',
        onRefresh: _loadInitialData,
      );
    }

    if (_jobList.isEmpty) {
      return EmptyDataAnimation(
        icon: Icons.search_off,
        iconColor: Colors.grey[400],
        title: 'Data Tidak Ditemukan',
        message: 'Belum ada data job untuk filter ini.',
        onRefresh: _fetchJobs,
      );
    }

    return ListView.builder(
      itemCount: _jobList.length,
      itemBuilder: (context, index) {
        final job = _jobList[index];
        final isSelected = _selectedIndex == index;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          child: ListTile(
            tileColor: isSelected ? Colors.blue.shade50 : Colors.white,
            title: Text(
              job.nomor,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              job.detail,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedIndex = null;
                } else {
                  _selectedIndex = index;
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final bool canAct = _selectedIndex != null;

    final bool canEdit = canAct;
    final bool canDelete = canAct && _isItAdmin;
    const bool canCreate = true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomBarButton(
            icon: Icons.description,
            label: 'Detail',
            color: Colors.blue.shade700,
            onPressed: canAct ? _onDetailPressed : null,
          ),
          _buildBottomBarButton(
            icon: Icons.edit,
            label: 'Edit',
            color: Colors.orange.shade700,
            onPressed: canEdit ? _onEditPressed : null,
          ),
          _buildBottomBarButton(
            icon: Icons.add_circle,
            label: 'Baru',
            color: Colors.green.shade700,
            onPressed: canCreate ? _onNewPressed : null,
          ),
          _buildBottomBarButton(
            icon: Icons.delete_forever,
            label: 'Hapus',
            color: Colors.red.shade700,
            onPressed: canDelete ? _onDeletePressed : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: onPressed == null ? Colors.grey : color, size: 28),
          Text(
            label,
            style: TextStyle(
              color: onPressed == null ? Colors.grey : color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI AKSI ---

  void _onDetailPressed() {
    if (_selectedIndex == null) return;
    final nomor = _jobList[_selectedIndex!].nomor;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobItDetPage(nomor: nomor),
      ),
    );
  }

  void _onNewPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobItFormPage(
          isItAdmin: _isItAdmin,
          userKode: _userKode,
          userCabang: _userCabang,
          userNama: _userNama,
        ),
      ),
    ).then((isSuccess) {
      if (isSuccess == true && mounted) {
        _fetchJobs();
      }
    });
  }

  void _onEditPressed() {
    if (_selectedIndex == null) return;

    final job = _jobList[_selectedIndex!];
    if (!_isItAdmin && job.detail.toLowerCase().contains('status: proses')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Tidak bisa diedit. Job sudah dikonfirmasi/diproses oleh IT.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final nomor = job.nomor;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobItFormPage(
          nomor: nomor,
          isItAdmin: _isItAdmin,
          userKode: _userKode,
          userCabang: _userCabang,
          userNama: _userNama,
        ),
      ),
    ).then((isSuccess) {
      if (isSuccess == true && mounted) {
        _fetchJobs();
      }
    });
  }

  void _onDeletePressed() async {
    if (_selectedIndex == null) return;
    final nomor = _jobList[_selectedIndex!].nomor;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus tiket $nomor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final headers = await _getAuthHeaders(isPostOrDelete: true);
      final uri = Uri.parse('${Config.baseUrl}/jobit/jobs/$nomor');
      final response = await http.delete(uri, headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Berhasil dihapus'),
              backgroundColor: Colors.green),
        );
        _fetchJobs();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ??
            'Gagal menghapus. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }
}
