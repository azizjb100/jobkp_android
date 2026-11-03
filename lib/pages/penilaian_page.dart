import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart'; // Simulasi API

class LapNilaiPage extends StatefulWidget {
  const LapNilaiPage({super.key});

  @override
  State<LapNilaiPage> createState() => _LapNilaiPageState();
}

class _LapNilaiPageState extends State<LapNilaiPage> {
  final _dateController = TextEditingController();
  String? selectedJawab;
  String? selectedArea;
  String lokasiFilter = 'All';

  List<String> penanggungJawab = [];
  List<String> areaList = [];
  List<String> hasilList = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadPenanggungJawab();
  }

  Future<void> _loadPenanggungJawab() async {
    final data = await ApiService.getPenanggungJawab();
    setState(() {
      penanggungJawab = data;
    });
  }

  Future<void> _loadArea(String jawab) async {
    final data = await ApiService.getAreaByJawab(jawab);
    setState(() {
      areaList = data;
      selectedArea = null;
    });
  }

  Future<void> _prosesData() async {
    if (selectedJawab == null) {
      _showSnack('Silakan pilih penanggung jawab');
      return;
    }
    if (selectedArea == null) {
      _showSnack('Silakan pilih area');
      return;
    }

    setState(() => isLoading = true);
    final data = await ApiService.getLaporan(
      jawab: selectedJawab!,
      area: selectedArea!,
      tanggal: _dateController.text,
    );

    setState(() {
      hasilList = data;
      isLoading = false;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Nilai')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📅 Date Picker
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Tanggal',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _dateController.text =
                        DateFormat('yyyy-MM-dd').format(date);
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            // 👤 Dropdown Penanggung Jawab
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Penanggung Jawab'),
              value: selectedJawab,
              items: penanggungJawab
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() => selectedJawab = val);
                if (val != null) _loadArea(val);
              },
            ),
            const SizedBox(height: 12),

            // 📍 Dropdown Area
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Area'),
              value: selectedArea,
              items: areaList
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedArea = val),
            ),
            const SizedBox(height: 16),

            // ✅ Checkbox filter lokasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FilterChip(
                  label: const Text('Atas'),
                  selected: lokasiFilter == 'Atas',
                  onSelected: (val) =>
                      setState(() => lokasiFilter = val ? 'Atas' : 'All'),
                ),
                FilterChip(
                  label: const Text('Bawah'),
                  selected: lokasiFilter == 'Bawah',
                  onSelected: (val) =>
                      setState(() => lokasiFilter = val ? 'Bawah' : 'All'),
                ),
                FilterChip(
                  label: const Text('Semua'),
                  selected: lokasiFilter == 'All',
                  onSelected: (val) => setState(() => lokasiFilter = 'All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🔘 Tombol Proses
            ElevatedButton.icon(
              onPressed: isLoading ? null : _prosesData,
              icon: const Icon(Icons.search),
              label: const Text('Proses'),
            ),

            const SizedBox(height: 16),

            // 📋 Hasil
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasilList.isEmpty
                      ? const Center(child: Text('Belum ada data'))
                      : ListView.builder(
                          itemCount: hasilList.length,
                          itemBuilder: (context, i) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.assignment_turned_in),
                              title: Text(hasilList[i]),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
