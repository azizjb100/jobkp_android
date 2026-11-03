import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Impor service yang benar
import '../services/api_service.dart';
import '../data/technician_model.dart';

class JobDetail {
  final String nama;
  final String satuan;
  final double qty;
  JobDetail({required this.nama, required this.satuan, required this.qty});
  factory JobDetail.fromJson(Map<String, dynamic> json) {
    return JobDetail(
      nama: json['nama'] ?? '',
      satuan: json['satuan'] ?? '',
      qty: (json['qty'] != null)
          ? double.tryParse(json['qty'].toString()) ?? 0.0
          : 0.0,
    );
  }
}

class SparepartPengajuan {
  final String nama;
  final String satuan;
  final double qty;
  SparepartPengajuan(
      {required this.nama, required this.satuan, required this.qty});
  factory SparepartPengajuan.fromJson(Map<String, dynamic> json) {
    return SparepartPengajuan(
      nama: json['nama'] ?? '',
      satuan: json['satuan'] ?? '',
      qty: (json['qty'] != null)
          ? double.tryParse(json['qty'].toString()) ?? 0.0
          : 0.0,
    );
  }
}

class JobDetailResponse {
  final Map<String, dynamic> header;
  final List<JobDetail> jobDetails;
  final List<SparepartPengajuan> sparepartDetails;

  JobDetailResponse({
    required this.header,
    required this.jobDetails,
    required this.sparepartDetails,
  });

  factory JobDetailResponse.fromJson(Map<String, dynamic> json) {
    return JobDetailResponse(
      header: json['header'] ?? {},
      jobDetails: (json['job_details'] as List<dynamic>?)
              ?.map((e) => JobDetail.fromJson(e))
              .toList() ??
          [],
      sparepartDetails: (json['sparepart_details'] as List<dynamic>?)
              ?.map((e) => SparepartPengajuan.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// --- Class EditKonfirmasiPage dan _EditKonfirmasiPageState ---

class EditKonfirmasiPage extends StatefulWidget {
  final String nomor;
  final String tanggal;
  final String user;
  final String kerusakan;
  final String bagian;
  final String keterangan;
  final String teknisi;
  final String jadwalPengerjaan;
  final int userRole;
  final String jobDivisi;
  final String konfirTeknisi;
  final String teknisiBantu;
  final String statusSelesai;
  final String ketProses;
  final String pengajuanBarang;

  const EditKonfirmasiPage({
    super.key,
    required this.nomor,
    required this.tanggal,
    required this.user,
    required this.kerusakan,
    required this.bagian,
    required this.keterangan,
    required this.teknisi,
    this.jadwalPengerjaan = '',
    required this.userRole,
    required this.jobDivisi,
    required this.konfirTeknisi,
    required this.teknisiBantu,
    required this.statusSelesai,
    required this.ketProses,
    required this.pengajuanBarang,
  });

  @override
  State<EditKonfirmasiPage> createState() => _EditKonfirmasiPageState();
}

class _EditKonfirmasiPageState extends State<EditKonfirmasiPage> {
  // --- State Variables ---
  bool _isLoading = true;
  bool _isGA = false;
  bool _isTeknisi = false;
  bool _isReadOnly = false;

  bool konfirmasiGA = false;
  DateTime? tglAwal;
  DateTime? tglAkhir;
  Technician? selectedTeknisi;

  bool konfirmasiTeknisi = false;
  bool pengajuanGudang = false;
  bool proses = false;
  bool selesai = false;
  final TextEditingController ketProsesController = TextEditingController();
  Technician? selectedTeknisiBantu;

  List<Technician> technicians = [];
  // Daftar Controller untuk menampung data sparepart yang diajukan
  final List<Map<String, TextEditingController>> _sparepartControllers = [];

  get data => null;

  @override
  void initState() {
    super.initState();
    _isGA = widget.userRole == 9;
    _isTeknisi = widget.userRole == 2;
    _loadInitialData();
  }

  @override
  void dispose() {
    ketProsesController.dispose();
    for (var controllers in _sparepartControllers) {
      controllers['nama']?.dispose();
      controllers['satuan']?.dispose();
      controllers['qty']?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      // =======================
      // 1. Load Teknisi
      // =======================
      final techData = await ApiService.getTechnicians();
      if (!mounted) return;
      technicians = techData.map((item) => Technician.fromJson(item)).toList();

      // =======================
      // 2. Load Job Detail
      // =======================
      final jobDetailResponse = await ApiService.getJobDetail(widget.nomor);

      // =======================
      // 3. Pre-fill GA Jadwal
      // =======================
      if (widget.jadwalPengerjaan.isNotEmpty &&
          widget.jadwalPengerjaan.contains('s.d')) {
        final parts = widget.jadwalPengerjaan.split('s.d');
        if (parts.length == 2) {
          try {
            final startDate = parts[0].trim();
            final endDate = parts[1].trim();

            if (startDate.isNotEmpty && startDate != '-') {
              tglAwal = DateFormat('dd-MM-yyyy').parse(startDate);
            }
            if (endDate.isNotEmpty && endDate != '-') {
              tglAkhir = DateFormat('dd-MM-yyyy').parse(endDate);
            }
          } catch (e) {
            print("Error parsing date range: $e");
          }
        }
      }

      // =======================
      // 4. Pre-fill Konfirmasi GA
      // =======================
      if (widget.teknisi.isNotEmpty && widget.teknisi != '-') {
        konfirmasiGA = true;

        final existingTech = technicians.firstWhere(
          (t) => t.nama == widget.teknisi,
          orElse: () => Technician(kode: '', nama: ''),
        );

        if (existingTech.kode.isNotEmpty) {
          selectedTeknisi = existingTech;
        }
      }

      // =======================
      // 5. Status Teknisi
      // =======================
      if (widget.konfirTeknisi.trim().startsWith("Sudah")) {
        konfirmasiTeknisi = true;
      }

      if (widget.statusSelesai.trim().startsWith("Selesai")) {
        selesai = true;
        _isReadOnly = true;
      } else if (widget.statusSelesai.trim().startsWith("Proses")) {
        proses = true;
      }

      // =======================
      // 6. Handling Sparepart
      // =======================

      final bool hasPengajuan =
          widget.pengajuanBarang.trim().toLowerCase() == 'ya' ||
              (int.tryParse(widget.pengajuanBarang.trim()) ?? 0) == 1;

// Sparepart sebenarnya ada di job_details
      final spareparts = jobDetailResponse.jobDetails ?? [];

// Jika ada sparepart yang sudah pernah diajukan → tampilkan
      if (spareparts.isNotEmpty) {
        pengajuanGudang = true; // checkbox otomatis ON

        for (var item in spareparts) {
          _sparepartControllers.add({
            'nama': TextEditingController(text: item.nama ?? ''),
            'satuan': TextEditingController(text: item.satuan ?? ''),
            'qty': TextEditingController(text: item.qty?.toString() ?? '0'),
          });
        }
      }

// Jika belum ada sparepart tapi teknisi buka & pengajuan YA → beri 1 row kosong
      else if (_isTeknisi && !_isReadOnly && hasPengajuan) {
        pengajuanGudang = true;
        _addSparepartRow();
      }

      // =======================
      // 7. Keterangan Proses
      // =======================
      ketProsesController.text = widget.ketProses;

      // =======================
      // 8. Teknisi Bantu
      // =======================
      if (widget.teknisiBantu.isNotEmpty && widget.teknisiBantu != '-') {
        final existingTechBantu = technicians.firstWhere(
          (t) => t.nama == widget.teknisiBantu,
          orElse: () => Technician(kode: '', nama: ''),
        );

        if (existingTechBantu.kode.isNotEmpty) {
          selectedTeknisiBantu = existingTechBantu;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data awal: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addSparepartRow() {
    setState(() {
      _sparepartControllers.add({
        'nama': TextEditingController(),
        'satuan': TextEditingController(),
        'qty': TextEditingController(),
      });
    });
  }

  void _removeSparepartRow(int index) {
    setState(() {
      _sparepartControllers[index]['nama']?.dispose();
      _sparepartControllers[index]['satuan']?.dispose();
      _sparepartControllers[index]['qty']?.dispose();
      _sparepartControllers.removeAt(index);
    });
  }

  Future<void> _saveData() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      Map<String, dynamic> payload = {};

      // Payload GA
      if (_isGA) {
        if (konfirmasiGA &&
            (tglAwal == null || tglAkhir == null || selectedTeknisi == null)) {
          throw Exception("Lengkapi Jadwal dan Teknisi untuk konfirmasi GA.");
        }
        payload.addAll({
          "konfirGA": konfirmasiGA,
          "teknisiId": selectedTeknisi?.kode,
          "jadwal1": tglAwal != null
              ? DateFormat('yyyy-MM-dd').format(tglAwal!)
              : null,
          "jadwal2": tglAkhir != null
              ? DateFormat('yyyy-MM-dd').format(tglAkhir!)
              : null,
        });
      }

      // Payload Teknisi
      if (_isTeknisi) {
        // [PERBAIKAN] Validasi Keterangan
        // Keterangan hanya wajib jika (dikonfirmasi) DAN (TIDAK selesai)
        if (konfirmasiTeknisi && !selesai && ketProsesController.text.isEmpty) {
          throw Exception("Isi Keterangan Proses terlebih dahulu.");
        }

        payload.addAll({
          "konfirTeknisi": konfirmasiTeknisi,
          "status": selesai ? 1 : (proses ? 2 : 0),

          // [PERBAIKAN] Kirim ' ' jika selesai (meniru Delphi)
          "keteranganTeknisi": selesai ? ' ' : ketProsesController.text,

          "teknisiBantuId": selectedTeknisiBantu?.kode ?? '',
          "pengajuanSparepart": pengajuanGudang,
        });

        if (pengajuanGudang) {
          for (var controllers in _sparepartControllers) {
            final nama = controllers['nama']!.text;
            final satuan = controllers['satuan']!.text;
            final qty = double.tryParse(controllers['qty']!.text) ?? 0;
            if (nama.isNotEmpty && (satuan.isEmpty || qty <= 0)) {
              throw Exception(
                  "Data sparepart '${nama}' belum lengkap (cek satuan dan qty).");
            }
          }

          final List<Map<String, dynamic>> sparepartDetails =
              _sparepartControllers.map((controllers) {
            return {
              'nama': controllers['nama']!.text,
              'satuan': controllers['satuan']!.text,
              'qty': double.tryParse(controllers['qty']!.text) ?? 0.0,
            };
          }).toList();

          sparepartDetails
              .removeWhere((item) => item['nama'].toString().trim().isEmpty);

          if (sparepartDetails.isNotEmpty) {
            payload['details'] = sparepartDetails;
          }
        }
      }

      if (payload.isEmpty) {
        throw Exception("Role tidak dikenali, tidak ada data untuk disimpan.");
      }

      await ApiService.updateJob(widget.nomor, payload);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Data berhasil diperbarui."),
          backgroundColor: Colors.green));

      Navigator.pop(context, true); // Go back
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ Gagal: ${e.toString()}"),
          backgroundColor: Colors.red));
    }
  }

  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text("Memuat...")),
          body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
          title: const Text("Konfirmasi Pengajuan Perbaikan"),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white),
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection(),
            const SizedBox(height: 15),
            _buildKonfirmasiGA(),
            const SizedBox(height: 15),
            _buildKonfirmasiTeknisi(),

            // [PERBAIKAN] Ganti '!selesai' menjadi '!_isReadOnly'
            if ((_isGA || _isTeknisi) && !_isReadOnly) ...[
              const SizedBox(height: 20),
              _buildActionButtons(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _buildReadOnlyField("No. Kebutuhan", widget.nomor),
            _buildReadOnlyField("Tanggal", widget.tanggal),
            _buildReadOnlyField("User", widget.user),
            _buildReadOnlyField("Divisi", widget.jobDivisi),
            _buildReadOnlyField("Bagian", widget.bagian),
            _buildReadOnlyField("Kerusakan", widget.kerusakan),
            _buildReadOnlyField("Keterangan", widget.keterangan),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        readOnly: true,
        initialValue: value, // Gunakan initialValue
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildKonfirmasiGA() {
    // [PERBAIKAN] Ganti 'selesai' menjadi '_isReadOnly'
    final bool isGaDisabled = !_isGA || _isReadOnly;
    return AbsorbPointer(
      absorbing: isGaDisabled,
      child: Opacity(
        opacity: isGaDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: konfirmasiGA ? Colors.green[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: konfirmasiGA ? Colors.green : Colors.grey.shade400),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text("Dikonfirmasi GA",
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                value: konfirmasiGA,
                onChanged: (val) => setState(() => konfirmasiGA = val!),
              ),
              if (konfirmasiGA) ...[
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _buildDatePicker("Jadwal Awal", tglAwal,
                            (picked) => setState(() => tglAwal = picked))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildDatePicker("Jadwal Akhir", tglAkhir,
                            (picked) => setState(() => tglAkhir = picked))),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTeknisiDropdown(
                    label: "Teknisi",
                    value: selectedTeknisi,
                    onChanged: (val) => setState(() => selectedTeknisi = val),
                    enabled: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKonfirmasiTeknisi() {
    // [PERBAIKAN] Ganti 'selesai' menjadi '_isReadOnly'
    final bool isTeknisiDisabled = !_isTeknisi || _isReadOnly;
    return AbsorbPointer(
      absorbing: isTeknisiDisabled,
      child: Opacity(
        opacity: isTeknisiDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: konfirmasiTeknisi ? Colors.cyan[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: konfirmasiTeknisi ? Colors.cyan : Colors.grey.shade400),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text("Dikonfirmasi Teknisi",
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                value: konfirmasiTeknisi,
                onChanged: (val) => setState(() => konfirmasiTeknisi = val!),
              ),
              if (konfirmasiTeknisi) ...[
                const Divider(),
                CheckboxListTile(
                    title: const Text("Pengajuan Sparepart/Gudang"),
                    value: pengajuanGudang,
                    onChanged: (val) => setState(() => pengajuanGudang = val!),
                    controlAffinity: ListTileControlAffinity.leading),
                if (pengajuanGudang) _buildSparepartSection(),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                        child: CheckboxListTile(
                            title: const Text("Proses"),
                            value: proses,
                            onChanged: (val) => setState(() {
                                  proses = val!;
                                  if (val) selesai = false;
                                }),
                            controlAffinity: ListTileControlAffinity.leading)),
                    Expanded(
                        child: CheckboxListTile(
                            title: const Text("Selesai"),
                            value: selesai,
                            onChanged: (val) => setState(() {
                                  selesai = val!;
                                  if (val) proses = false;
                                }),
                            controlAffinity: ListTileControlAffinity.leading)),
                  ],
                ),
                const SizedBox(height: 8),

                // [PERBAIKAN 11] Hapus 'if (!selesai)'
                // Biarkan TextField selalu terlihat jika 'konfirmasiTeknisi' true
                _buildTextField("Keterangan Proses", ketProsesController),

                const SizedBox(height: 12),
                _buildTeknisiDropdown(
                    label: "Teknisi Bantu",
                    value: selectedTeknisiBantu,
                    onChanged: (val) =>
                        setState(() => selectedTeknisiBantu = val),
                    enabled: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSparepartSection() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Daftar Kebutuhan Sparepart",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const Divider(),
          if (_sparepartControllers.isEmpty)
            const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                    child: Text("Klik 'Tambah Sparepart' untuk memulai.",
                        style: TextStyle(color: Colors.grey))))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sparepartControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 4,
                          child: _buildSparepartField(
                              _sparepartControllers[index]['nama']!,
                              'Nama Barang')),
                      const SizedBox(width: 8),
                      Expanded(
                          flex: 3,
                          child: _buildSparepartField(
                              _sparepartControllers[index]['satuan']!,
                              'Satuan')),
                      const SizedBox(width: 8),
                      Expanded(
                          flex: 2,
                          child: _buildSparepartField(
                              _sparepartControllers[index]['qty']!, 'Qty',
                              isNumber: true)),
                      IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => _removeSparepartRow(index)),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Tambah Sparepart"),
                onPressed: _addSparepartRow),
          ),
        ],
      ),
    );
  }

  Widget _buildSparepartField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget _buildDatePicker(
      String label, DateTime? value, Function(DateTime) onPicked) {
    return TextFormField(
      initialValue: value != null ? DateFormat('dd-MM-yyyy').format(value) : '',
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
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
          onPicked(picked);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Pilih tanggal',
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildTeknisiDropdown(
      {required String label,
      required Technician? value,
      required ValueChanged<Technician?>? onChanged,
      bool enabled = true}) {
    final List<DropdownMenuItem<Technician?>> dropdownItems = [];

    dropdownItems.add(
      const DropdownMenuItem<Technician?>(
        value: null,
        child: Text(
          '- Tidak Ada -',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
        ),
      ),
    );

    dropdownItems.addAll(
      technicians.map((tech) {
        return DropdownMenuItem<Technician?>(
            value: tech, child: Text(tech.nama));
      }).toList(),
    );

    return DropdownButtonFormField<Technician?>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: value,
      items: dropdownItems,
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      maxLines: 2,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
            onPressed: _saveData,
            tooltip: 'Simpan'),
        const SizedBox(width: 40),
        IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red, size: 40),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Batal'),
      ],
    );
  }
}
