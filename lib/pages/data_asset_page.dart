import 'package:flutter/material.dart';

class DetAssetPage extends StatefulWidget {
  final String nomor; // nomor job yang dikirim dari halaman sebelumnya
  const DetAssetPage({super.key, required this.nomor});

  @override
  State<DetAssetPage> createState() => _DetAssetPageState();
}

class _DetAssetPageState extends State<DetAssetPage> {
  // Simulasi data JSON (nanti bisa diganti dari API)
  Map<String, dynamic> detailData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // simulasi ambil data seperti query di Delphi
  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 600)); // delay loading
    // data dummy sesuai struktur Delphi
    detailData = {
      "Nomor": widget.nomor,
      "Tanggal": "23-10-2025 14:22",
      "Cabang": "Yogyakarta",
      "User": "Budi Santoso",
      "Divisi": "GA",
      "Bagian": "Maintenance",
      "Kerusakan": "AC bocor",
      "Jenis": "Perbaikan",
      "Keterangan": "Diperlukan penggantian pipa freon",
      "Kepentingan": "Top Urgent",
      "Dikonfirmasi GA": "Sudah - 23-10-2025 09:00 oleh Arif",
      "Jadwal Pengerjaan": "24-10-2025 s.d 25-10-2025",
      "Teknisi": "Dimas",
      "Teknisi Bantu": "Andi",
      "Dikonfirmasi Teknisi": "Sudah - 23-10-2025 11:00",
      "Pengajuan Barang": "Ya",
      "Nomor Sparepart": "SPP-231023001",
      "Ket. Proses": "Menunggu sparepart",
      "Selesai Dikerjakan": "Belum",
      "Close": "Belum"
    };
    setState(() => isLoading = false);
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Detail Perbaikan'),
        backgroundColor: Colors.blue[600],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Kartu utama
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildRow("Nomor", detailData["Nomor"] ?? ""),
                        _buildRow("Tanggal", detailData["Tanggal"] ?? ""),
                        _buildRow("Cabang", detailData["Cabang"] ?? ""),
                        _buildRow("User", detailData["User"] ?? ""),
                        _buildRow("Divisi", detailData["Divisi"] ?? ""),
                        _buildRow("Bagian", detailData["Bagian"] ?? ""),
                        _buildRow("Kerusakan", detailData["Kerusakan"] ?? ""),
                        _buildRow("Jenis", detailData["Jenis"] ?? ""),
                        _buildRow("Keterangan", detailData["Keterangan"] ?? ""),
                        _buildRow(
                            "Kepentingan", detailData["Kepentingan"] ?? ""),
                        _buildRow("Dikonfirmasi GA",
                            detailData["Dikonfirmasi GA"] ?? ""),
                        _buildRow("Jadwal Pengerjaan",
                            detailData["Jadwal Pengerjaan"] ?? ""),
                        _buildRow("Teknisi", detailData["Teknisi"] ?? ""),
                        _buildRow(
                            "Teknisi Bantu", detailData["Teknisi Bantu"] ?? ""),
                        _buildRow("Dikonfirmasi Teknisi",
                            detailData["Dikonfirmasi Teknisi"] ?? ""),
                        _buildRow("Pengajuan Barang",
                            detailData["Pengajuan Barang"] ?? ""),
                        _buildRow("Nomor Sparepart",
                            detailData["Nomor Sparepart"] ?? ""),
                        _buildRow(
                            "Ket. Proses", detailData["Ket. Proses"] ?? ""),
                        _buildRow("Selesai Dikerjakan",
                            detailData["Selesai Dikerjakan"] ?? ""),
                        _buildRow("Close", detailData["Close"] ?? ""),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Kembali"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
