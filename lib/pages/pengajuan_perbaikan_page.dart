import 'package:flutter/material.dart';
import 'dart:math';

class PengajuanPerbaikanPage extends StatefulWidget {
  final String nama;
  final String divisi;

  const PengajuanPerbaikanPage({
    super.key,
    required this.nama,
    required this.divisi,
  });

  @override
  State<PengajuanPerbaikanPage> createState() => _PengajuanPerbaikanPageState();
}

class _PengajuanPerbaikanPageState extends State<PengajuanPerbaikanPage> {
  final TextEditingController nomorController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController divisiController = TextEditingController();
  final TextEditingController lokasiController = TextEditingController();
  final TextEditingController keteranganController = TextEditingController();

  @override
  void initState() {
    super.initState();
    generateNomorOtomatis();
    namaController.text = widget.nama;
    divisiController.text = widget.divisi;
  }

  void generateNomorOtomatis() {
    final now = DateTime.now();
    final random = Random().nextInt(999);
    final nomor =
        'JB-${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}${random.toString().padLeft(3, '0')}';
    nomorController.text = nomor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Pengajuan Perbaikan'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _buildTextField(
              controller: nomorController,
              label: "Nomor Pengajuan",
              enabled: false,
              readOnlyColor: Colors.grey[300]!,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: namaController,
              label: "Nama Pemohon",
              enabled: false,
              readOnlyColor: Colors.grey[300]!,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: divisiController,
              label: "Divisi",
              enabled: false,
              readOnlyColor: Colors.grey[300]!,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: lokasiController,
              label: "Lokasi / Bagian yang Diperbaiki",
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: keteranganController,
              label: "Keterangan Tambahan",
              maxLines: 4,
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Pengajuan berhasil dikirim!')),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Kirim Pengajuan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    int maxLines = 1,
    Color? readOnlyColor,
  }) {
    return FocusScope(
      child: Focus(
        onFocusChange: (hasFocus) => setState(() {}),
        child: TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor:
                enabled ? Colors.white : readOnlyColor ?? Colors.grey[200],
            labelStyle: TextStyle(
              color: enabled ? Colors.blueGrey : Colors.grey[600],
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[500]!, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
