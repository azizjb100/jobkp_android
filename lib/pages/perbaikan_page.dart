import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../data/detasset_model.dart';
import 'detasset_page.dart';
import '../../../../config.dart';
import '../services/session_manager.dart';

class _RedirectException implements Exception {}

class PerbaikanPage extends StatefulWidget {
  final DetAsset? asset;
  final String? nama;
  final String? divisi;
  final String? cabang;
  final String? userKode;

  const PerbaikanPage({
    super.key,
    this.asset,
    this.nama,
    this.divisi,
    this.cabang,
    this.userKode,
  });

  @override
  State<PerbaikanPage> createState() => _PerbaikanPageState();
}

class _PerbaikanPageState extends State<PerbaikanPage> {
  final _formKey = GlobalKey<FormState>();
  final SessionManager _sessionManager = SessionManager();
  late final TextEditingController bagianController;
  late final TextEditingController kerusakanController;
  late final TextEditingController ketController;

  String _nomorValue = '';
  String _tanggalValue = '';
  String _userValue = '';

  bool _isEditMode = false;
  bool _isLoading = true;
  String? _selectedJenis;
  String? _selectedDivisi;
  String _statusKepentingan = 'Urgent';

  List<String> _jenisOptions = [];
  List<String> _divisiOptions = [];

  bool _isKonfirmasiGA = false;
  bool _isSelesai = false;
  bool _isClose = false;

  @override
  void initState() {
    super.initState();
    bagianController = TextEditingController();
    kerusakanController = TextEditingController();
    ketController = TextEditingController();

    _isEditMode = widget.asset != null;
    _loadInitialData();
  }

  Future<Map<String, String>> _getAuthHeaders({bool isPost = false}) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final headers = <String, String>{};
    headers['Authorization'] = 'Bearer $token';
    if (isPost) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  Future<void> _loadInitialData() async {
    try {
      if (_isEditMode) {
        _fillFormForEdit();
        await _fetchFormData(runValidation: false);
      } else {
        await _fetchFormData(runValidation: true);
        if (!mounted) return;

        _fillFormForNew();
      }
    } catch (e) {
      if (mounted && e is! _RedirectException) {
        _showBlockerDialog('Terjadi Error: ${e.toString()}', popTwice: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFormData({required bool runValidation}) async {
    final uri = Uri.parse(
        '${Config.baseUrl}/perbaikan/form-data?cabang=${widget.cabang}&user_kode=${widget.userKode}&validate=${runValidation ? '1' : '0'}');
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (runValidation && data['can_create_new'] == false) {
          await _showBlockerDialog(
              data['message'] ?? 'Tidak dapat membuat pengajuan baru.',
              pendingNomor: data['pending_nomor']);
          throw _RedirectException();
        }

        setState(() {
          _divisiOptions = List<String>.from(data['divisi_options'] ?? []);
          _jenisOptions = List<String>.from(data['jenis_options'] ?? []);
          if (!_isEditMode) {
            if (_divisiOptions.isNotEmpty) {
              _selectedDivisi = _divisiOptions.contains(widget.divisi)
                  ? widget.divisi
                  : _divisiOptions.first;
            }
            if (_jenisOptions.isNotEmpty) {
              _selectedJenis = _jenisOptions.first;
            }
            bagianController.text = data['default_bagian'] ?? '';
          }
        });
      } else {
        throw Exception('Server Error: Gagal memuat data form.');
      }
    } catch (e) {
      if (e is _RedirectException) rethrow;
      throw Exception('Terjadi Kesalahan: ${e.toString()}');
    }
  }

  void _fillFormForEdit() {
    final asset = widget.asset!;

    _nomorValue = asset.jbNomor;
    _tanggalValue = asset.tglPengajuan;
    _userValue = asset.peminta;
    _selectedDivisi = asset.divisi;
    bagianController.text = asset.bagian;
    kerusakanController.text = asset.lokasi;
    _selectedJenis = asset.jenis;
    ketController.text = asset.keterangan ?? '';
    _statusKepentingan = asset.status;
    setState(() {
      _isKonfirmasiGA = asset.konfirGA?.trim().startsWith('Sudah') ?? false;
      _isSelesai = asset.selesai?.trim().startsWith('Sudah') ?? false;
      _isClose = asset.close?.trim().startsWith('Sudah') ?? false;
    });
  }

  void _fillFormForNew() {
    // [PERBAIKAN 5] Isi nilai ke variabel String, bukan controller
    _nomorValue = '[Akan Dibuat Otomatis]';
    _tanggalValue = '[Akan Dibuat Otomatis]';
    _userValue = widget.nama ?? 'N/A';
  }

  @override
  void dispose() {
    // [PERBAIKAN 6] Hapus controller read-only dari dispose
    // nomorController.dispose();
    // tanggalController.dispose();
    // userController.dispose();

    // Controller ini tetap ada
    bagianController.dispose();
    kerusakanController.dispose();
    ketController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isKonfirmasiGA) {
      _showErrorSnackbar(
          'Data sudah dikonfirmasi GA dan tidak dapat diubah lagi.');
      return;
    }
    if (_isSelesai) {
      _showErrorSnackbar(
          'Pekerjaan sudah selesai dan tidak dapat diubah lagi.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin akan menyimpan data ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Simpan')),
        ],
      ),
    );
    if (confirm != true) return;
    if (_isEditMode) {
      await _updateData();
    } else {
      await _saveNewData();
    }
  }

  Future<void> _promptCloseJob() async {
    if (!_isKonfirmasiGA) {
      _showErrorSnackbar('Belum dikonfirmasi oleh GA. Belum bisa diclose.');
      return;
    }
    if (!_isSelesai) {
      _showErrorSnackbar('Pekerjaan masih dalam proses. Belum bisa diclose.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Close'),
        content: const Text(
            'Apakah Anda yakin pekerjaan ini sudah selesai dan akan di-Close?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Close Pekerjaan')),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      await _performCloseJob();
    }
  }

  Future<void> _performCloseJob() async {
    setState(() => _isLoading = true);
    final payload = {
      'jb_nomor': _nomorValue, // [FIX] Ambil dari _nomorValue
    };
    try {
      final headers = await _getAuthHeaders(isPost: true);
      final response = await http
          .post(
            Uri.parse('${Config.baseUrl}/perbaikan/close'),
            headers: headers,
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      final result = json.decode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        _showSuccessSnackbar('Pekerjaan berhasil di-Close!');
        Navigator.pop(context, true); // Keluar dan refresh halaman list
      } else {
        throw Exception(result['message'] ?? 'Gagal melakukan close.');
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Terjadi Kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNewData() async {
    setState(() => _isLoading = true);

    try {
      final headers = await _getAuthHeaders(isPost: true);

      // [FIX] Ambil tanggal dari 'now', bukan controller
      final String tglSql =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final payload = {
        'jb_tanggal': tglSql, // [FIX]
        'jb_user': widget.userKode,
        'jb_cabang': widget.cabang,
        'jb_divisi': _selectedDivisi,
        'jb_bagian': bagianController.text,
        'jb_lokasi': kerusakanController.text,
        'jb_jenis': _selectedJenis,
        'jb_ket': ketController.text,
        'jb_urgent': _statusKepentingan == 'Urgent' ? 0 : 1,
      };

      final response = await http
          .post(
            Uri.parse('${Config.baseUrl}/perbaikan/save'),
            headers: headers,
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      final result = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSuccessSnackbar('Data baru berhasil disimpan!');
        Navigator.pop(context, true); // Kembali & refresh
      } else {
        throw Exception(result['message'] ?? 'Gagal menyimpan data.');
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Terjadi Kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateData() async {
    setState(() => _isLoading = true);

    try {
      final headers = await _getAuthHeaders(isPost: true);

      final payload = {
        'jb_nomor': _nomorValue, // [FIX] Ambil dari _nomorValue
        'jb_divisi': _selectedDivisi,
        'jb_bagian': bagianController.text,
        'jb_lokasi': kerusakanController.text,
        'jb_jenis': _selectedJenis,
        'jb_ket': ketController.text,
        'jb_urgent': _statusKepentingan == 'Urgent' ? 0 : 1,
      };

      final response = await http
          .put(
            Uri.parse('${Config.baseUrl}/perbaikan/$_nomorValue'), // [FIX]
            headers: headers,
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      final result = json.decode(response.body);

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Data berhasil diperbarui!');
        Navigator.pop(context, true); // Kembali & refresh
      } else {
        throw Exception(result['message'] ?? 'Gagal memperbarui data.');
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Terjadi Kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // [FIX] Diubah untuk menangani redirect atau pop
  Future<void> _showBlockerDialog(String message,
      {String? pendingNomor, bool popTwice = false}) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Informasi'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext); // 1. Tutup dialog

              if (pendingNomor != null) {
                // Skenario Bloker: Ganti halaman 'Form Baru' ini
                // dengan halaman list 'DetAssetPage'
                Navigator.pushReplacement(
                  // 2A.
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetAssetPage(
                      divisi: widget.divisi ?? '',
                      cabang: widget.cabang ?? '',
                      userKode: widget.userKode ?? '',
                    ),
                  ),
                );
              } else if (popTwice) {
                // 2B. Skenario Error: Kembali ke halaman sebelumnya
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainBlue = Colors.blue.shade700;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        title:
            Text(_isEditMode ? 'Edit Pengajuan' : 'Form Pengajuan Perbaikan'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isEditMode) ...[
                      _buildStatusCheckboxes(),
                      const SizedBox(height: 16),
                    ],

                    // [PERBAIKAN 7] Panggil _buildReadOnlyTextField baru
                    _buildReadOnlyTextField(
                        label: 'Nomor Otomatis', value: _nomorValue),
                    const SizedBox(height: 10),
                    _buildReadOnlyTextField(
                        label: 'Tanggal Pengajuan', value: _tanggalValue),
                    const SizedBox(height: 10),
                    _buildReadOnlyTextField(label: 'User', value: _userValue),
                    const SizedBox(height: 10),

                    _buildDropdown(
                      label: 'Divisi',
                      value: _selectedDivisi,
                      items: _divisiOptions,
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _selectedDivisi = value);
                      },
                      disabled: _isKonfirmasiGA || _isSelesai,
                    ),
                    const SizedBox(height: 10),
                    _buildTextFormField(
                      controller: bagianController,
                      label: 'Bagian',
                      validator: (v) =>
                          v!.isEmpty ? 'Bagian wajib diisi' : null,
                      enabled: !_isKonfirmasiGA && !_isSelesai,
                    ),
                    const SizedBox(height: 10),
                    _buildTextFormField(
                      controller: kerusakanController,
                      label: 'Uraian Kerusakan / Kebutuhan',
                      validator: (v) =>
                          v!.isEmpty ? 'Uraian wajib diisi' : null,
                      maxLines: 3,
                      enabled: !_isKonfirmasiGA && !_isSelesai,
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      label: 'Jenis Perbaikan',
                      value: _selectedJenis,
                      items: _jenisOptions,
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _selectedJenis = value);
                      },
                      disabled: _isKonfirmasiGA || _isSelesai,
                    ),
                    const SizedBox(height: 10),
                    _buildTextFormField(
                        controller: ketController,
                        label: 'Keterangan Tambahan',
                        maxLines: 3,
                        enabled: !_isKonfirmasiGA && !_isSelesai),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      label: 'Kepentingan',
                      value: _statusKepentingan,
                      items: ['Urgent', 'Top Urgent'],
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _statusKepentingan = value);
                      },
                      disabled: _isKonfirmasiGA || _isSelesai,
                    ),
                    const SizedBox(height: 10),

                    // Logika Tombol yang Dinamis
                    if (_isEditMode) ...[
                      if (_isKonfirmasiGA && _isSelesai && !_isClose)
                        _buildCloseButton(Colors.green.shade700)
                      else if (!_isKonfirmasiGA && !_isSelesai)
                        _buildSubmitButton(mainBlue)
                    ] else ...[
                      _buildSubmitButton(mainBlue),
                    ],
                    const SizedBox(height: 12),
                    if (!_isEditMode) _buildViewDataButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCheckboxes() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200)),
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('Dikonfirmasi GA'),
            value: _isKonfirmasiGA,
            onChanged: null,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
          CheckboxListTile(
            title: const Text('Selesai Dikerjakan'),
            value: _isSelesai,
            onChanged: null,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
          CheckboxListTile(
            title: const Text('Sudah di-Close User'),
            value: _isClose,
            onChanged: null,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(Color color) {
    return ElevatedButton.icon(
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_circle),
      onPressed: _isLoading ? null : _promptCloseJob,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      label: const Text('Close Pekerjaan'),
    );
  }

  // [PERBAIKAN 8] Fungsi ini sekarang menerima String, bukan Controller
  Widget _buildReadOnlyTextField(
      {required String value, required String label}) {
    return TextFormField(
      readOnly: true,
      initialValue: value, // Gunakan initialValue
      decoration: _formDecoration(label, readOnly: true),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _formDecoration(label, readOnly: !enabled),
      validator: validator,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      enabled: enabled,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool disabled = false,
  }) {
    final currentValue = items.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: _formDecoration(label, readOnly: disabled),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: disabled ? null : onChanged,
      validator: (val) => val == null ? 'Pilihan ini wajib diisi' : null,
    );
  }

  Widget _buildSubmitButton(Color color) {
    return ElevatedButton.icon(
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.save),
      onPressed:
          (_isLoading || _isKonfirmasiGA || _isSelesai) ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      label: Text(_isEditMode ? 'Update Data' : 'Simpan'),
    );
  }

  Widget _buildViewDataButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.list_alt),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetAssetPage(
              divisi: widget.divisi ?? '',
              cabang: widget.cabang ?? '',
              userKode: widget.userKode ?? '',
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      label: const Text('Lihat Data Pengajuan'),
    );
  }

  InputDecoration _formDecoration(String label, {bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      labelStyle: const TextStyle(fontSize: 16, color: Colors.black54),
      filled: true,
      fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
