import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config.dart';
import '../data/job_model.dart';
import '../data/technician_model.dart';
import 'edit_konfirmasi_page.dart';
import '../services/session_manager.dart';

// [PERBAIKAN] Impor file animasi (sesuaikan path jika perlu)
import '../core/widget/empty_data_animation.dart';

class KonfirmasiPerbaikanPage extends StatefulWidget {
  final String nama;
  final String divisi;

  const KonfirmasiPerbaikanPage({
    super.key,
    required this.nama,
    required this.divisi,
  });

  @override
  State<KonfirmasiPerbaikanPage> createState() =>
      _KonfirmasiPerbaikanPageState();
}

class _KonfirmasiPerbaikanPageState extends State<KonfirmasiPerbaikanPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Job> _jobList = [];
  final _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String _selectedStatus = 'ALL';
  String _closeStatus = 'NOT CLOSE';
  String _selectedCabang = 'ALL';
  String _selectedTeknisi = 'ALL';

  List<Technician> _technicians = [];
  List<String> _cabangOptions = ['ALL'];
  final String _cabangUrl = '${Config.baseUrl}/konfirmasi/branches';
  final List<String> _statusOptions = ['ALL', 'Belum', 'Proses', 'Selesai'];
  final List<String> _closeStatusOptions = ['NOT CLOSE', 'CLOSE', 'ALL'];

  int _userRole = 0;
  String? _userTechnicianCode;
  String? _userKode;
  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now;
    _endDate = now;
    _loadInitialData();
    _updateDateTextFields();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _userRole = await _sessionManager.getRole();
    _userTechnicianCode = await _sessionManager.getTechnicianCode();
    _userKode = await _sessionManager.getUserKode();

    debugPrint("--- SESI DILOAD ---");
    debugPrint("Role: $_userRole");
    debugPrint("Kode Teknisi Sesi: $_userTechnicianCode");
    debugPrint("User Kode Sesi: $_userKode");
    debugPrint("--------------------");

    if (_userRole == 2) {
      String? teknisiFilter;
      if (_userTechnicianCode != null && _userTechnicianCode!.isNotEmpty) {
        teknisiFilter = _userTechnicianCode;
      } else if (_userKode != null && _userKode!.isNotEmpty) {
        teknisiFilter = _userKode;
      }

      if (mounted) {
        setState(() {
          _selectedTeknisi = teknisiFilter ?? 'ALL';
          _selectedCabang = 'ALL';
        });
      }
    }

    await _fetchDropdownData();
    await _fetchJobs();
  }

  void _updateDateTextFields() {
    final format = DateFormat('dd/MM/yyyy');
    if (_startDate != null) {
      _startDateController.text = format.format(_startDate!);
    }
    if (_endDate != null) {
      _endDateController.text = format.format(_endDate!);
    }
  }

  Future<void> _fetchBranches() async {
    try {
      final uri = Uri.parse(_cabangUrl);
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<String> fetchedBranches =
            data.map((item) => item.toString()).toList();

        setState(() {
          _cabangOptions = fetchedBranches;

          if (!_cabangOptions.contains(_selectedCabang)) {
            _selectedCabang = 'ALL';
          }
        });
      } else {
        // Fallback jika API gagal (misal: 404, 500)
        debugPrint('Gagal memuat data cabang: ${response.statusCode}');
        if (mounted) {
          setState(() {
            // Opsional: set manual jika gagal total
            _cabangOptions = ['ALL', 'P01', 'P02', 'P03', 'P04', 'P05'];
          });
        }
      }
    } catch (e) {
      debugPrint('Gagal memuat data cabang: $e');
      if (mounted) {
        // Fallback jika terjadi error koneksi
        setState(() {
          _cabangOptions = ['ALL', 'P01', 'P02', 'P03', 'P04', 'P05'];
        });
      }
    }
  }

  Future<void> _fetchTechnicians() async {
    try {
      final uri = Uri.parse('${Config.baseUrl}/konfirmasi/technicians');
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _technicians = data.map((item) => Technician.fromJson(item)).toList();
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat data teknisi: $e');
    }
  }

  Future<void> _fetchDropdownData() async {
    await Future.wait([
      _fetchBranches(), // Ambil data cabang
      _fetchTechnicians(), // Ambil data teknisi
    ]);
  }

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

  Future<void> _fetchJobs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queryParams = <String, String>{};

      // Filter Tanggal
      if (_startDate != null) {
        queryParams['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
      }
      if (_endDate != null) {
        queryParams['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
      }

      // --- LOGIKA FILTER BERDASARKAN ROLE ---
      if (_userRole == 2) {
        // ROLE 2: TEKNISI (Filter harus otomatis ke teknisi yang login)

        // Penentuan Kode Teknisi yang disederhanakan
        final String? teknisiFilter = _userTechnicianCode?.isNotEmpty == true
            ? _userTechnicianCode
            : _userKode?.isNotEmpty == true
                ? _userKode
                : null;

        if (teknisiFilter != null && teknisiFilter != 'ALL') {
          queryParams['technician'] = teknisiFilter;
          queryParams['includeBantu'] = 'true';
        }

        if (_selectedCabang != 'ALL') {
          queryParams['branch'] = _selectedCabang;
        }

        // >>> PERBAIKAN UTAMA DI SINI: Status untuk Role 2 <<<
        final String selectedStatusUpper = _selectedStatus.toUpperCase();

        if (selectedStatusUpper == 'ALL') {
          // PERUBAHAN: ALL untuk Teknisi HANYA menampilkan BARU dan PROSES.
          // Status SELESAI (yang di backend = 1) dihilangkan secara default.
          queryParams['status'] = 'BARU,PROSES';
        } else {
          // Jika memilih status spesifik (BARU, PROSES, atau SELESAI),
          // kirim status tunggal. Teknisi BISA melihat SELESAI jika memilihnya.
          queryParams['status'] = selectedStatusUpper;
        }
        // >>> AKHIR PERBAIKAN STATUS ROLE 2 <<<
      } else {
        // ROLE NON-TEKNISI (1, 3, 9, dll.)

        // Filter Cabang (Hanya jika bukan ALL)
        if (_selectedCabang != 'ALL') {
          queryParams['branch'] = _selectedCabang;
        }

        // Filter Teknisi (Hanya jika bukan ALL)
        if (_selectedTeknisi != 'ALL') {
          queryParams['technician'] = _selectedTeknisi;
          queryParams['includeBantu'] = 'true';
        }

        // Status untuk Role Non-Teknisi: ALL = TIDAK MENGIRIM PARAMETER STATUS
        if (_selectedStatus.toUpperCase() != 'ALL') {
          queryParams['status'] = _selectedStatus.toUpperCase();
        }
      }
      // --- AKHIR LOGIKA FILTER BERDASARKAN ROLE ---

      // Filter Close dan Search (Berlaku untuk semua Role)
      if (_closeStatus != 'ALL') queryParams['closeStatus'] = _closeStatus;
      if (_searchController.text.isNotEmpty) {
        queryParams['search'] = _searchController.text;
      }

      debugPrint('Query Params: $queryParams');

      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${Config.baseUrl}/konfirmasi/jobs')
          .replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _jobList = data.map((item) => Job.fromJson(item)).toList();
        });
      } else {
        final errorBody = json.decode(response.body);
        // Membersihkan pesan error
        throw Exception(
            errorBody['message'] ?? 'Error Server: ${response.statusCode}');
      }
    } on TimeoutException {
      if (mounted) {
        setState(
            () => _errorMessage = 'Server tidak merespons. Periksa koneksi.');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith("Exception: ")) {
          msg = msg.substring(11);
        }
        setState(() => _errorMessage = msg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
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

    if (date != null) {
      setState(() {
        isStartDate ? _startDate = date : _endDate = date;
        _updateDateTextFields();
      });
      _fetchJobs();
    }
  }

  Future<void> _navigateToEditPage(Job? job) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditKonfirmasiPage(
          nomor: job?.nomor ?? '',
          user: job?.cabang ?? '',
          tanggal: job?.tanggal ?? '',
          kerusakan: job?.lokasi ?? '',
          jobDivisi: job?.divisi ?? '',
          bagian: job?.bagian ?? '',
          keterangan: job?.keterangan ?? '',
          teknisi: job?.teknisi ?? '',
          jadwalPengerjaan: job?.jadwalPengerjaan ?? '',
          userRole: _userRole,
          konfirTeknisi: job?.konfirTeknisi ?? 'Belum',
          teknisiBantu: job?.teknisiBantu ?? '-',
          statusSelesai: job?.statusSelesai ?? 'Belum',
          ketProses: job?.ketProses ?? '',
          pengajuanBarang: job?.pengajuanBarang ?? 'Tidak',
        ),
      ),
    );
    if (result == true && mounted) {
      _fetchJobs();
    }
  }

  // [PERBAIKAN 1] Tambahkan parameter 'valueColor'
  Widget _buildInfo(String label, String? value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 4,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          const Text(' : '),
          Expanded(
            flex: 6,
            // [PERBAIKAN] Terapkan style dengan 'valueColor'
            child: Text(
              value ?? '-',
              style: TextStyle(
                color: valueColor, // Jika null, akan pakai warna default
                fontWeight: valueColor != null
                    ? FontWeight.bold
                    : null, // Opsional: tebalkan
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [PERBAIKAN 2] Perbarui _buildContent
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return EmptyDataAnimation(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'Oops, Terjadi Kesalahan',
        message: _errorMessage!,
        onRefresh: _fetchJobs,
      );
    }

    if (_jobList.isEmpty) {
      return EmptyDataAnimation(
        icon: Icons.search_off,
        iconColor: Colors.grey[400],
        title: 'Tidak Ada Data Ditemukan',
        message: 'Coba ubah filter atau tanggal Anda.',
        onRefresh: _fetchJobs,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 8),
        itemCount: _jobList.length,
        itemBuilder: (context, index) {
          final job = _jobList[index];

          // [PERBAIKAN 3] Logika untuk menentukan warna
          // 'startsWith' lebih aman daripada '=='
          final bool isBelumSelesai =
              job.statusSelesai.trim().toLowerCase().startsWith('belum');
          final bool isBelumClose =
              job.statusClose.trim().toLowerCase().startsWith('belum');

          // Tentukan warna. Jika belum selesai, beri warna merah.
          final Color? selesaiColor = isBelumSelesai ? Colors.red[700] : null;
          // Tentukan warna. Jika belum di-close, beri warna merah.
          final Color? closeColor = isBelumClose ? Colors.red[700] : null;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          job.nomor,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        width: 30,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit,
                              color: Colors.blueGrey, size: 20),
                          onPressed: () => _navigateToEditPage(job),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildInfo('Tanggal', job.tanggal, valueColor: selesaiColor),
                  _buildInfo('Peminta', job.cabang, valueColor: selesaiColor),
                  _buildInfo('Divisi', job.divisi, valueColor: selesaiColor),
                  _buildInfo('Kerusakan', job.lokasi, valueColor: selesaiColor),
                  _buildInfo('Jenis', job.jenis, valueColor: selesaiColor),
                  _buildInfo('Kepentingan', job.kepentingan,
                      valueColor: selesaiColor),
                  _buildInfo('DikonfirmasiGA', job.konfirGa,
                      valueColor: selesaiColor),
                  _buildInfo('JadwalPengerjaan', job.jadwalPengerjaan,
                      valueColor: selesaiColor),
                  _buildInfo('Teknisi', job.teknisi, valueColor: selesaiColor),
                  _buildInfo('TeknisiBantu', job.teknisiBantu,
                      valueColor: selesaiColor),
                  _buildInfo('Keterangan', job.ketProses,
                      valueColor: selesaiColor),

                  // [PERBAIKAN 4] Kirim warna ke widget _buildInfo
                  _buildInfo('Selesai', job.statusSelesai,
                      valueColor: selesaiColor),
                  _buildInfo('Close', job.statusClose, valueColor: closeColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<String>> teknisiDropdownItems;

    if (_userRole == 2) {
      String displayName = "Loading...";
      if (_selectedTeknisi != "ALL") {
        try {
          final tech =
              _technicians.firstWhere((t) => t.kode == _selectedTeknisi);
          displayName = tech.nama;
        } catch (e) {
          displayName = _selectedTeknisi;
        }
      }

      teknisiDropdownItems = [
        DropdownMenuItem(
          value: _selectedTeknisi,
          child: Text(displayName, overflow: TextOverflow.ellipsis),
        )
      ];
    } else {
      teknisiDropdownItems = [
        const DropdownMenuItem(
          value: 'ALL',
          child: Text('ALL'),
        ),
        ..._technicians.map((Technician tech) {
          return DropdownMenuItem(
            value: tech.kode,
            child: Text(tech.nama, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
      ];
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text('Konfirmasi Perbaikan',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          centerTitle: true),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(children: [
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
                  const SizedBox(width: 8),
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
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCabang,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Cabang',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: _cabangOptions.map((String item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedCabang = val;
                        });
                        _fetchJobs();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTeknisi,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Teknisi',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        filled: _userRole == 2,
                        fillColor: _userRole == 2 ? Colors.grey[200] : null,
                      ),
                      items: teknisiDropdownItems,
                      onChanged: _userRole == 2
                          ? null
                          : (val) {
                              if (val == null) return;
                              setState(() {
                                _selectedTeknisi = val;
                              });
                              _fetchJobs();
                            },
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _buildDropdown(
                          _selectedStatus,
                          _statusOptions,
                          'Status',
                          (val) => setState(() => _selectedStatus = val!))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildDropdown(
                          _closeStatus,
                          _closeStatusOptions,
                          'Close',
                          (val) => setState(() => _closeStatus = val!)))
                ]),
                const SizedBox(height: 8),
                TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                        hintText: 'Cari nomor, lokasi, keterangan...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 12)),
                    onSubmitted: (_) => _fetchJobs()),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          onPressed: () => _navigateToEditPage(null),
          tooltip: 'Tambah Pengajuan',
          child: const Icon(Icons.add)),
    );
  }

  Widget _buildDropdown(String value, List<String> items, String label,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        items: items
            .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (val) {
          if (val == null) return;
          onChanged(val);
          _fetchJobs();
        });
  }
}

// Widget animasi _EmptyDataAnimation (tidak diubah)
class _EmptyDataAnimation extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Future<void> Function() onRefresh;

  const _EmptyDataAnimation({
    required this.title,
    required this.message,
    required this.onRefresh,
    this.icon = Icons.search_off,
    this.iconColor,
  });

  @override
  State<_EmptyDataAnimation> createState() => _EmptyDataAnimationState();
}

class _EmptyDataAnimationState extends State<_EmptyDataAnimation> {
  bool _isVisible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _isVisible = !_isVisible;
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24.0),
            child: AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon,
                      size: 80, color: widget.iconColor ?? Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
