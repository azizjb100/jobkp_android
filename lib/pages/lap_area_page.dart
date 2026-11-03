import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LapAreaPage extends StatefulWidget {
  const LapAreaPage({super.key});

  @override
  State<LapAreaPage> createState() => _LapAreaPageState();
}

class _LapAreaPageState extends State<LapAreaPage> {
  final TextEditingController _dateController = TextEditingController();
  String? _selectedCabang;
  bool _isLoading = false;
  List<String> _cabangList = [];
  List<String> _laporanList = [];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadCabangList();
  }

  // --- Simulasi ambil data cabang dari database
  Future<void> _loadCabangList() async {
    await Future.delayed(const Duration(milliseconds: 500)); // simulasi delay
    setState(() {
      _cabangList = ['Jakarta', 'Bandung', 'Surabaya', 'Yogyakarta'];
      _selectedCabang = _cabangList[0];
    });
  }

  // --- Fungsi ketika tombol Proses ditekan
  Future<void> _prosesLaporan() async {
    if (_selectedCabang == null || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Pilih cabang dan tanggal terlebih dahulu")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulasi pengambilan data dari database
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _laporanList = [
        "Andi\nArea Utara = 3",
        "Budi\nArea Timur = 5",
        "Sinta\nArea Selatan = 2",
      ];
      _isLoading = false;
    });
  }

  // --- Fungsi memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Area'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Input Tanggal ---
            const Text(
              'Tanggal:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Pilih tanggal',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- ComboBox Cabang ---
            const Text(
              'Cabang:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCabang,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _cabangList
                  .map((cabang) => DropdownMenuItem<String>(
                        value: cabang,
                        child: Text(cabang),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCabang = value),
            ),

            const SizedBox(height: 16),

            // --- Tombol Proses ---
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.search),
                label: const Text(
                  "Proses",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _prosesLaporan,
              ),
            ),

            const SizedBox(height: 20),

            // --- Hasil Laporan ---
            const Text(
              'Hasil Laporan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _laporanList.isEmpty
                      ? const Center(child: Text('Belum ada data.'))
                      : ListView.builder(
                          itemCount: _laporanList.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.assignment),
                                title: Text(
                                  _laporanList[index],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
