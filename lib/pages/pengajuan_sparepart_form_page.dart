// File: lib/pages/pengajuan_sparepart_form_page.dart (VERSI LENGKAP DIPERBAIKI)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../../config.dart';
import '../services/session_manager.dart';

//==============================================================================
// BAGIAN 1: MODEL DATA
//==============================================================================

class JobDetailItem {
  final String nama;
  final String satuan;
  final num qty;

  JobDetailItem({
    required this.nama,
    required this.satuan,
    required this.qty,
  });

  factory JobDetailItem.fromJson(Map<String, dynamic> json) {
    return JobDetailItem(
      // [PERBAIKAN] Sesuaikan dengan kolom jbd_...
      nama: json['jbd_nama'] ?? '',
      satuan: json['jbd_satuan'] ?? '',
      qty: num.tryParse(json['jbd_qty'].toString()) ?? 0,
    );
  }
}

class PengajuanDetailItem {
  final String kode;
  final String nama;
  final String satuan;
  final TextEditingController qtyController;

  PengajuanDetailItem({
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.qtyController,
  });
}

class JobLookupItem {
  final String nomor;
  final String detail;
  JobLookupItem({required this.nomor, required this.detail});
  factory JobLookupItem.fromJson(Map<String, dynamic> json) {
    return JobLookupItem(
      nomor: json['Nomor'] ?? '',
      detail: json['Detail'] ?? '',
    );
  }
}

class SparepartLookupItem {
  final String kode;
  final String nama;
  final String satuan;
  final num stok;

  SparepartLookupItem({
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.stok,
  });

  factory SparepartLookupItem.fromJson(Map<String, dynamic> json) {
    return SparepartLookupItem(
      // [UPDATE] Menggunakan prefix brg_
      kode: json['brg_kode'] ?? '',
      nama: json['brg_nama'] ?? '',
      satuan: json['brg_satuan'] ?? '',
      stok: num.tryParse(json['stok'].toString()) ?? 0,
    );
  }
}
//==============================================================================
// BAGIAN 2: Halaman Utama Form
//==============================================================================

class PengajuanSparepartFormPage extends StatefulWidget {
  final String? nomorPengajuan;
  const PengajuanSparepartFormPage({super.key, this.nomorPengajuan});

  @override
  State<PengajuanSparepartFormPage> createState() =>
      _PengajuanSparepartFormPageState();
}

class _PengajuanSparepartFormPageState
    extends State<PengajuanSparepartFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool get _isEditMode => widget.nomorPengajuan != null;

  // 🆕 State untuk status pengajuan & mode readonly
  String _statusPengajuan = '';
  bool _isReadonly = false;

  final SessionManager _sessionManager = SessionManager();

  final TextEditingController _nomorController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _ketController = TextEditingController();

  List<JobDetailItem> _jobDetailItems = [];
  List<PengajuanDetailItem> _pengajuanDetailItems = [];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nomorController.text = widget.nomorPengajuan!;
      _loadDataForEdit();
    } else {
      _nomorController.text = '[BARU]';
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var item in _pengajuanDetailItems) {
      item.qtyController.dispose();
    }
    _nomorController.dispose();
    _jobController.dispose();
    _ketController.dispose();
    super.dispose();
  }

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

  Future<void> _loadDataForEdit() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _getAuthHeaders();
      final uri =
          Uri.parse('${Config.baseUrl}/pengajuan/${widget.nomorPengajuan}');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final header = result['data']['header'];
          final details = result['data']['details'] as List;

          setState(() {
            // 1. PERBAIKAN NOMOR JOB: Gunakan alias 'spp_job' sesuai SQL backend
            _jobController.text = header['spp_job'] ?? '';

            _ketController.text = header['spp_ket'] ?? '';

            final String statusText = header['spp_status'] ?? 'BELUM';
            _statusPengajuan = statusText;
            _isReadonly = (statusText == 'SUDAH' || statusText == 'CLOSE');

            // 2. PERBAIKAN DETAIL & QTY: Gunakan nama kolom asli dari SQL detail
            _pengajuanDetailItems = details.map((d) {
              return PengajuanDetailItem(
                kode: d['mind_brg_kode'] ?? '', // Sesuai SQL: d.mind_brg_kode
                nama: d['brg_nama'] ?? '', // Sesuai SQL: b.brg_nama
                satuan: d['brg_satuan'] ?? '', // Sesuai SQL: b.brg_satuan
                qtyController: TextEditingController(
                  text: (d['mind_jumlah'] ?? 0)
                      .toString(), // Sesuai SQL: d.mind_jumlah
                ),
              );
            }).toList();

            _isLoading = false;
          });

          // Panggil detail job referensi jika nomor job ada
          if (_jobController.text.isNotEmpty) {
            await _fetchJobDetails(_jobController.text);
          }
        }
      }
    } catch (e) {
      print("Error Load Edit: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchJobDetails(String jobNomor) async {
    setState(() {
      _jobDetailItems = [];
    });
    try {
      final uri =
          Uri.parse('${Config.baseUrl}/pengajuan/lookup/job-details/$jobNomor');

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final List<dynamic> data = result['data'];
          setState(() {
            _jobDetailItems =
                data.map((item) => JobDetailItem.fromJson(item)).toList();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _jobDetailItems = [];
        });
      }
    }
  }

  Future<void> _openJobLookup() async {
    // Tidak boleh diakses jika sedang readonly
    if (_isReadonly) return;

    final selectedJob = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _JobLookupDialog(),
    );

    if (selectedJob != null) {
      setState(() {
        _jobController.text = selectedJob;
        _fetchJobDetails(selectedJob);
      });
    }
  }

  Future<void> _openSparepartLookup() async {
    // Tidak boleh diakses jika sedang readonly
    if (_isReadonly) return;

    final selectedSparepart = await showDialog<SparepartLookupItem>(
      context: context,
      builder: (BuildContext context) => const _SparepartLookupDialog(),
    );

    if (selectedSparepart != null) {
      if (_pengajuanDetailItems
          .any((item) => item.kode == selectedSparepart.kode)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sparepart sudah ada di dalam daftar.'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      setState(() {
        _pengajuanDetailItems.add(PengajuanDetailItem(
          kode: selectedSparepart.kode,
          nama: selectedSparepart.nama,
          satuan: selectedSparepart.satuan,
          qtyController: TextEditingController(text: '1'),
        ));
      });
    }
  }

  void _removeSparepartItem(int index) {
    // Tidak boleh diakses jika sedang readonly
    if (_isReadonly) return;

    setState(() {
      _pengajuanDetailItems[index].qtyController.dispose();
      _pengajuanDetailItems.removeAt(index);
    });
  }

  Future<void> _saveData() async {
    // 🛑 Blokir penyimpanan jika readonly (CLOSE)
    if (_isReadonly) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pengajuan yang sudah CLOSE tidak bisa disimpan/diubah.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_pengajuanDetailItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Detail sparepart tidak boleh kosong.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final header = {
        // Gunakan min_nomor yang konsisten
        'min_nomor': _isEditMode ? widget.nomorPengajuan : '[BARU]',
        'min_spk_nomor': _jobController.text,
        'min_ket': _ketController.text,
      };

      final details = _pengajuanDetailItems.map((item) {
        return {
          'brg_kode': item.kode,
          'brg_qty': double.tryParse(item.qtyController.text) ?? 0,
        };
      }).toList();

      final headers = await _getAuthHeaders(isPost: true);

      late final http.Response response;

      if (_isEditMode) {
        final uri =
            Uri.parse('${Config.baseUrl}/pengajuan/${widget.nomorPengajuan}');
        response = await http
            .put(
              uri,
              headers: headers,
              body: json.encode({
                'header': header,
                'details': details,
              }),
            )
            .timeout(const Duration(seconds: 20));
      } else {
        final uri = Uri.parse('${Config.baseUrl}/pengajuan');
        response = await http
            .post(
              uri,
              headers: headers,
              body: json.encode({
                'header': header,
                'details': details,
              }),
            )
            .timeout(const Duration(seconds: 20));
      }

      final result = json.decode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message']), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(result['message'] ?? 'Gagal menyimpan data');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menyimpan: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
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
      appBar: AppBar(
        title: Text(_isEditMode
            ? (_isReadonly ? 'Lihat Pengajuan (CLOSE)' : 'Edit Pengajuan')
            : 'Buat Pengajuan Baru'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🆕 Kirim status readonly ke input Job
                    _buildJobInput(isReadonly: _isReadonly),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nomorController,
                      readOnly: true,
                      decoration:
                          _inputDecoration('Nomor Pengajuan', readOnly: true),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ketController,
                      // 🆕 Terapkan readonly pada Keterangan
                      readOnly: _isReadonly,
                      decoration:
                          _inputDecoration('Keterangan', readOnly: _isReadonly),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    const Text('Kebutuhan Sparepart (Referensi dari Job)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _buildJobDetailTable(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sparepart yang Diajukan',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),

                        // 🆕 Sembunyikan tombol tambah jika readonly
                        if (!_isReadonly)
                          IconButton.filled(
                            icon: const Icon(Icons.add),
                            onPressed: _openSparepartLookup,
                            tooltip: 'Tambah Sparepart dari Database',
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.green),
                          )
                      ],
                    ),
                    const Divider(),
                    // 🆕 Kirim status readonly ke tabel detail
                    _buildPengajuanDetailTable(isReadonly: _isReadonly),
                    const SizedBox(height: 40),

                    // 🆕 Sembunyikan tombol Simpan jika readonly
                    if (!_isReadonly)
                      ElevatedButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label: const Text('Simpan'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white),
                        onPressed: _isLoading ? null : _saveData,
                      )
                  ],
                ),
              ),
            ),
    );
  }

  // 🆕 Tambahkan parameter isReadonly
  Widget _buildJobInput({bool isReadonly = false}) {
    // Jika mode edit ATAU readonly (CLOSE)
    if (_isEditMode || isReadonly) {
      return TextFormField(
        controller: _jobController,
        readOnly: true,
        decoration: _inputDecoration('Nomor Job', readOnly: true),
      );
    } else {
      // Mode Tambah Baru (Job harus dipilih)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _jobController,
              readOnly: true,
              decoration: _inputDecoration('Nomor Job'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nomor Job wajib dipilih' : null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.search),
            onPressed: _openJobLookup,
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
            ),
          ),
        ],
      );
    }
  }

  InputDecoration _inputDecoration(String label, {bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: readOnly,
      fillColor: readOnly ? Colors.grey[200] : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  Widget _buildJobDetailTable() {
    if (_jobDetailItems.isEmpty && _jobController.text.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child:
            Text('Tidak ada kebutuhan sparepart yang tercatat untuk Job ini.'),
      );
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('No.')),
        DataColumn(label: Text('Nama')),
        DataColumn(label: Text('Sat')),
        DataColumn(label: Text('Qty')),
      ],
      rows: _jobDetailItems.asMap().entries.map((entry) {
        int index = entry.key;
        JobDetailItem item = entry.value;
        return DataRow(cells: [
          DataCell(Text((index + 1).toString())),
          DataCell(Text(item.nama)),
          DataCell(Text(item.satuan)),
          DataCell(Text(item.qty.toStringAsFixed(0))),
        ]);
      }).toList(),
      headingRowHeight: 40,
      dataRowMinHeight: 35,
      dataRowMaxHeight: 40,
      columnSpacing: 16,
      horizontalMargin: 0,
      headingTextStyle:
          const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
    );
  }

  // 🆕 Tambahkan parameter isReadonly
  Widget _buildPengajuanDetailTable({bool isReadonly = false}) {
    return DataTable(
      columns: [
        const DataColumn(label: Text('No.')),
        const DataColumn(label: Text('Kode')),
        const DataColumn(label: Text('Nama')),
        const DataColumn(label: Text('Sat')),
        const DataColumn(label: Text('Qty')),
        // 🆕 Sembunyikan kolom Aksi jika readonly
        if (!isReadonly) const DataColumn(label: Text('Aksi')),
      ],
      rows: _pengajuanDetailItems.asMap().entries.map((entry) {
        int index = entry.key;
        PengajuanDetailItem item = entry.value;
        final cells = <DataCell>[
          DataCell(Text((index + 1).toString())),
          DataCell(Text(item.kode)),
          DataCell(Text(item.nama)),
          DataCell(Text(item.satuan)),
          DataCell(
            TextFormField(
              controller: item.qtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(border: InputBorder.none),
              // 🆕 Terapkan readonly pada Qty
              readOnly: isReadonly,
              validator: (v) => (isReadonly || // Lewati validasi jika readonly
                      v == null ||
                      v.isEmpty ||
                      (double.tryParse(v) ?? 0) <= 0)
                  ? (isReadonly
                      ? null
                      : 'Qty>0') // Tampilkan error hanya jika tidak readonly
                  : null,
            ),
          ),
        ];

        // 🆕 Tambahkan kolom Aksi (tombol hapus) hanya jika tidak readonly
        if (!isReadonly) {
          cells.add(DataCell(
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeSparepartItem(index),
            ),
          ));
        }
        return DataRow(cells: cells);
      }).toList(),
      headingRowHeight: 40,
      dataRowMinHeight: 35,
      dataRowMaxHeight: 55,
      columnSpacing: 10,
      horizontalMargin: 0,
      headingTextStyle:
          const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
    );
  }
}

//==============================================================================
// BAGIAN 3: Dialog Pencarian Job (Internal Widget)
//==============================================================================
class _JobLookupDialog extends StatefulWidget {
  const _JobLookupDialog();
  @override
  State<_JobLookupDialog> createState() => _JobLookupDialogState();
}

class _JobLookupDialogState extends State<_JobLookupDialog> {
  bool _isLoading = true;
  List<JobLookupItem> _jobList = [];
  List<JobLookupItem> _filteredList = [];
  final TextEditingController _searchController = TextEditingController();

  final SessionManager _sessionManager = SessionManager();
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _searchController.addListener(_filterJobs);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterJobs);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    try {
      final uri =
          Uri.parse('${Config.baseUrl}/pengajuan/lookup/available-jobs');

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final List<dynamic> data = result['data'];
          setState(() {
            _jobList =
                data.map((item) => JobLookupItem.fromJson(item)).toList();
            _filteredList = _jobList;
            _isLoading = false;
          });
        } else {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Gagal memuat data Job.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterJobs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = _jobList.where((job) {
        return job.nomor.toLowerCase().contains(query) ||
            job.detail.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _selectJob(JobLookupItem job) {
    Navigator.pop(context, job.nomor);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Nomor Job'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    labelText: 'Cari Nomor Job atau Keterangan',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder()),
                autofocus: true),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredList.isEmpty
                      ? const Center(
                          child: Text('Tidak ada Job yang tersedia.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final job = _filteredList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(job.nomor,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(job.detail),
                                onTap: () => _selectJob(job),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
      ],
    );
  }
}

//==============================================================================
// BAGIAN 4: Dialog Pencarian Sparepart (Internal Widget)
//==============================================================================
class _SparepartLookupDialog extends StatefulWidget {
  const _SparepartLookupDialog();
  @override
  State<_SparepartLookupDialog> createState() => _SparepartLookupDialogState();
}

class _SparepartLookupDialogState extends State<_SparepartLookupDialog> {
  bool _isLoading = true;
  List<SparepartLookupItem> _sparepartList = [];
  List<SparepartLookupItem> _filteredList = [];
  final TextEditingController _searchController = TextEditingController();

  final SessionManager _sessionManager = SessionManager();
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  @override
  void initState() {
    super.initState();
    _fetchSpareparts();
    _searchController.addListener(_filterSpareparts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSpareparts() async {
    try {
      final uri =
          Uri.parse('${Config.baseUrl}/pengajuan/lookup/available-spareparts');

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final List<dynamic> data = result['data'];
          setState(() {
            _sparepartList =
                data.map((item) => SparepartLookupItem.fromJson(item)).toList();
            _filteredList = _sparepartList;
            _isLoading = false;
          });
        } else {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Gagal memuat data Sparepart.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterSpareparts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = _sparepartList.where((sp) {
        return sp.kode.toLowerCase().contains(query) ||
            sp.nama.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _selectSparepart(SparepartLookupItem sparepart) {
    Navigator.pop(context, sparepart);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Sparepart'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    labelText: 'Cari Kode atau Nama',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder()),
                autofocus: true),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredList.isEmpty
                      ? const Center(child: Text('Sparepart tidak ditemukan.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final sp = _filteredList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(sp.nama,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    'Kode: ${sp.kode} | Stok: ${sp.stok.toStringAsFixed(0)} ${sp.satuan}'),
                                onTap: () => _selectSparepart(sp),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
      ],
    );
  }
}
