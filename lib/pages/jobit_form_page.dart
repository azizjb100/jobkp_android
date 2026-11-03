import 'dart:async';
import 'dart:convert'; // [FIX] Tambahkan
import 'package:http/http.dart' as http; // [FIX] Tambahkan
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/jobit_det_model.dart';
// [FIX] Hapus ApiService, kita ganti dengan http
// import '../services/api_service.dart';
import '../services/session_manager.dart'; // [FIX] Tambahkan
import '../../../../config.dart'; // [FIX] Tambahkan

class JobItFormPage extends StatefulWidget {
  final String? nomor; // Jika 'nomor' ada, ini mode Edit
  final bool isItAdmin; // 'zit' dari Delphi
  final String? userKode;
  final String? userCabang;
  final String? userNama;

  const JobItFormPage({
    super.key,
    this.nomor,
    required this.isItAdmin,
    this.userKode,
    this.userCabang,
    this.userNama,
  });

  @override
  State<JobItFormPage> createState() => _JobItFormPageState();
}

class _JobItFormPageState extends State<JobItFormPage> {
  final _formKey = GlobalKey<FormState>();
  final SessionManager _sessionManager = SessionManager(); // [FIX] Tambahkan

  // Controllers
  // [FIX] Hapus controller read-only
  // final _nomorController = TextEditingController();
  // final _tanggalController = TextEditingController();
  // final _userController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _ketController = TextEditingController();
  final _noteController = TextEditingController(); // mmnote

  // [FIX] Tambahkan state untuk data read-only
  String _nomorValue = '[OTOMATIS]';
  String _tanggalValue = DateFormat('dd/MM/yyyy').format(DateTime.now());
  String _userValue = '';

  // State
  bool _isLoading = true;
  String? _error;
  bool get _isEditMode => widget.nomor != null;

  // Dropdown & Checkbox State
  List<String> _itStaffList = [];
  String? _selectedIt;
  bool _isHardware = true;
  bool _isSoftware = false;

  // Status (dari admin IT)
  bool _isKonfirmasi = false;
  bool _isProses = false;
  bool _isSelesai = false;

  // Status (dari User)
  bool _isClose = false;

  @override
  void initState() {
    super.initState();
    _userValue =
        '${widget.userCabang} / ${widget.userNama}'; // Set user default
    _loadInitialData();
  }

  @override
  void dispose() {
    // [FIX] Hapus controller read-only dari dispose
    // _nomorController.dispose();
    // _tanggalController.dispose();
    // _userController.dispose();
    _lokasiController.dispose();
    _ketController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // [FIX] Tambahkan helper otentikasi
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

  Future<void> _loadInitialData() async {
    try {
      // [FIX] Ganti ApiService.getItStaffList
      final headers = await _getAuthHeaders();
      final staffUri = Uri.parse('${Config.baseUrl}/jobit/it-staff');
      final staffResponse = await http.get(staffUri, headers: headers);

      if (!mounted) return;
      if (staffResponse.statusCode != 200) {
        throw Exception('Gagal memuat daftar IT Staff');
      }

      final List<dynamic> staffData = json.decode(staffResponse.body);
      final staffList = List<String>.from(staffData);

      // Cek Mode
      if (_isEditMode) {
        // [FIX] Ganti ApiService.getItJobByNomor
        final jobUri =
            Uri.parse('${Config.baseUrl}/jobit/jobs/${widget.nomor!}');
        final jobResponse = await http.get(jobUri, headers: headers);

        if (!mounted) return;
        if (jobResponse.statusCode != 200) {
          throw Exception('Gagal memuat data job');
        }

        final jobResult = json.decode(jobResponse.body);
        if (jobResult['success'] != true) {
          throw Exception(jobResult['message'] ?? 'Gagal memuat data job');
        }
        final jobData = ItJobDetail.fromJson(jobResult['data']);
        _fillFormForEdit(jobData, staffList);
      } else {
        _fillFormForNew(staffList);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fillFormForNew(List<String> staffList) {
    setState(() {
      _itStaffList = staffList;
      if (staffList.isNotEmpty) {
        String defaultIT = staffList.first;
        if (widget.userCabang != 'P01' && staffList.length > 1) {
          defaultIT = staffList[1];
        }
        _selectedIt = defaultIT;
      }
      _isHardware = true;
    });
  }

  void _fillFormForEdit(ItJobDetail job, List<String> staffList) {
    setState(() {
      _itStaffList = staffList;
      if (staffList.contains(job.jbIt)) {
        _selectedIt = job.jbIt;
      } else if (staffList.isNotEmpty) {
        _selectedIt = staffList.first;
      }

      // [FIX] Isi ke state String, bukan controller
      _nomorValue = job.jbNomor;
      _tanggalValue =
          DateFormat('dd/MM/yyyy').format(DateTime.parse(job.tanggalOnly));
      _userValue = '${job.jbCabang} / ${job.userNama}';

      _lokasiController.text = job.jbLokasi;
      _ketController.text = job.jbKet;
      _noteController.text = job.jbNote;

      if (job.jbJenis.toUpperCase() == 'SOFTWARE') {
        _isHardware = false;
        _isSoftware = true;
      } else {
        _isHardware = true;
        _isSoftware = false;
      }

      _isKonfirmasi = job.jbKonfirit == 1;
      _isSelesai = job.jbSelesai == 1;
      _isProses = job.jbSelesai == 2;
      _isClose = job.jbTglClose.isNotEmpty;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    int statusSelesai = 0; // Belum
    if (_isProses) statusSelesai = 2;
    if (_isSelesai) statusSelesai = 1;
    String jenis = _isHardware ? 'HARDWARE' : 'SOFTWARE';

    final payload = {
      'jb_lokasi': _lokasiController.text,
      'jb_jenis': jenis,
      'jb_it': _selectedIt,
      'jb_ket': _ketController.text,
      'jb_tgl_close': _isClose,
      'jb_note': _noteController.text,
      'jb_konfirit': _isKonfirmasi,
      'jb_selesai': statusSelesai,
      'jb_cabang': widget.userCabang,
      'jb_user': widget.userKode,
    };

    try {
      // [FIX] Ganti ApiService dengan http + token
      final headers = await _getAuthHeaders(isPost: true);
      late final http.Response response;

      if (_isEditMode) {
        final uri = Uri.parse('${Config.baseUrl}/jobit/jobs/${widget.nomor!}');
        response =
            await http.put(uri, headers: headers, body: json.encode(payload));
      } else {
        final uri = Uri.parse('${Config.baseUrl}/jobit/jobs');
        response =
            await http.post(uri, headers: headers, body: json.encode(payload));
      }

      if (!mounted) return;

      final result = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Kirim 'true' untuk refresh
      } else {
        throw Exception(result['message'] ?? 'Gagal menyimpan data');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Job IT' : 'Buat Job IT'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildForm(),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildForm() {
    final bool isUserDisabled = _isKonfirmasi || _isClose;
    final bool isAdminDisabled = !widget.isItAdmin;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // [FIX] Ganti ke widget read-only yang aman
                child: _buildReadOnlyField(label: 'Nomor', value: _nomorValue),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: CheckboxListTile(
                  title: const Text('Close'),
                  value: _isClose,
                  onChanged: (val) {
                    setState(() => _isClose = val!);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildReadOnlyField(label: 'Tanggal', value: _tanggalValue),
          const SizedBox(height: 10),
          _buildReadOnlyField(label: 'User', value: _userValue),
          const SizedBox(height: 10),

          // --- Bagian Input User ---
          TextFormField(
            controller: _lokasiController,
            decoration: _formDecoration('Lokasi', readOnly: isUserDisabled),
            validator: (v) => v!.isEmpty ? 'Lokasi wajib diisi' : null,
            readOnly: isUserDisabled,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 10),
          _buildJenisToggle(disabled: isUserDisabled),
          const SizedBox(height: 10),
          _buildDropdownIT(disabled: isUserDisabled),
          const SizedBox(height: 10),
          TextFormField(
            controller: _ketController,
            decoration: _formDecoration('Keterangan', readOnly: isUserDisabled),
            maxLines: 4,
            readOnly: isUserDisabled,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // --- Bagian Admin IT ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAdminDisabled ? Colors.grey[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  title: const Text('Di konfirmasi IT'),
                  value: _isKonfirmasi,
                  onChanged: isAdminDisabled
                      ? null
                      : (val) {
                          setState(() => _isKonfirmasi = val!);
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Proses'),
                        value: _isProses,
                        onChanged: isAdminDisabled
                            ? null
                            : (val) {
                                setState(() {
                                  _isProses = val!;
                                  if (_isProses)
                                    _isSelesai = false; // Logic Delphi
                                });
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Selesai dikerjakan'),
                        value: _isSelesai,
                        onChanged: isAdminDisabled
                            ? null
                            : (val) {
                                setState(() {
                                  _isSelesai = val!;
                                  if (_isSelesai)
                                    _isProses = false; // Logic Delphi
                                });
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  decoration:
                      _formDecoration('Note IT', readOnly: isAdminDisabled),
                  maxLines: 4,
                  readOnly: isAdminDisabled,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJenisToggle({bool disabled = false}) {
    return Row(
      children: [
        const Text('Jenis', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 20),
        Expanded(
          child: CheckboxListTile(
            title: const Text('Hardware'),
            value: _isHardware,
            onChanged: disabled
                ? null
                : (val) {
                    setState(() {
                      _isHardware = true;
                      _isSoftware = false;
                    });
                  },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        Expanded(
          child: CheckboxListTile(
            title: const Text('Software'),
            value: _isSoftware,
            onChanged: disabled
                ? null
                : (val) {
                    setState(() {
                      _isHardware = false;
                      _isSoftware = true;
                    });
                  },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownIT({bool disabled = false}) {
    return DropdownButtonFormField<String>(
      value: _selectedIt,
      decoration: _formDecoration('IT', readOnly: disabled),
      items: _itStaffList.map((it) {
        return DropdownMenuItem(value: it, child: Text(it));
      }).toList(),
      onChanged: disabled
          ? null
          : (val) {
              setState(() => _selectedIt = val);
            },
      validator: (v) => v == null ? 'Silakan pilih staff IT' : null,
      disabledHint: _selectedIt != null ? Text(_selectedIt!) : null,
    );
  }

  // [PERBAIKAN 9] Fungsi ini sekarang menggunakan 'initialValue'
  Widget _buildReadOnlyField({
    required String value,
    required String label,
  }) {
    return TextFormField(
      initialValue: value, // <-- FIX
      readOnly: true,
      decoration: _formDecoration(label, readOnly: true),
    );
  }

  InputDecoration _formDecoration(String label, {bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: readOnly ? Colors.grey[200] : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildSaveButton() {
    if (!widget.isItAdmin && (_isKonfirmasi || _isClose)) {
      return const SizedBox.shrink();
    }
    if (widget.isItAdmin && _isClose) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save),
        label: Text(_isEditMode ? 'Update Data' : 'Simpan Tiket Baru'),
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
