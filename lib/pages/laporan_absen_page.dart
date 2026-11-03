// laporan_absen_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// [FIX] Import Config dan SessionManager
import '../../../../config.dart'; // Sesuaikan path jika perlu
import '../services/session_manager.dart'; // Sesuaikan path jika perlu

class LaporanAbsenPage extends StatefulWidget {
  const LaporanAbsenPage({super.key});

  @override
  State<LaporanAbsenPage> createState() => _LaporanAbsenPageState();
}

class _LaporanAbsenPageState extends State<LaporanAbsenPage> {
  // --- State Variables ---
  late DateTime _startDate;
  late DateTime _endDate;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  List<String> _bagianList = [];
  String? _selectedBagian;

  List<dynamic> _laporanData = [];
  bool _isLoading = false;
  String? _errorMessage;

  // [FIX] Tambahkan SessionManager
  final SessionManager _sessionManager = SessionManager();

  // [FIX] Hapus _baseUrl yang di-hardcode
  // final String _baseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    // [FIX] Set tanggal default ke awal dan akhir bulan
    final now = DateTime.now();
    _startDate = now;
    _endDate = now;
    _updateDateTextFields();
    _fetchBagianList();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // [FIX] Tambahkan helper untuk Auth Header (sama seperti di perbaikan_page)
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

  // [FIX] Tambahkan helper untuk update Teks Tanggal
  void _updateDateTextFields() {
    final format = DateFormat('dd MMM yyyy'); // Format sesuai UI Anda
    _startDateController.text = format.format(_startDate);
    _endDateController.text = format.format(_endDate);
  }

  Future<void> _fetchBagianList() async {
    try {
      // [FIX] Panggil endpoint dan header yang benar
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${Config.baseUrl}/absensi/bagian');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          // [FIX] Backend mengirim List<String>, bukan List<Map>
          _bagianList = List<String>.from(data);
          if (_bagianList.isNotEmpty) {
            _selectedBagian = _bagianList[0];
          }
        });
      } else {
        throw Exception(
            'Failed to load bagian list. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
      });
    }
  }

  Future<void> _fetchLaporan() async {
    if (_selectedBagian == null) {
      setState(() => _errorMessage = "Silakan pilih bagian terlebih dahulu.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _laporanData = [];
    });

    final formatter = DateFormat('yyyy-MM-dd');
    final String startDateStr = formatter.format(_startDate);
    final String endDateStr = formatter.format(_endDate);

    try {
      // [FIX] Panggil endpoint dan header yang benar
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${Config.baseUrl}/absensi/report')
          .replace(queryParameters: {
        'startDate': startDateStr,
        'endDate': endDateStr,
        'bagian': _selectedBagian,
      });

      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        setState(() {
          _laporanData = json.decode(response.body);
        });
      } else {
        throw Exception(
            'Failed to load report data. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- UI Helper Methods ---
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    // [PERBAIKAN] Bungkus showDatePicker dengan Theme
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      // [PERBAIKAN] Tambahkan 'builder' untuk membungkusnya dengan Theme
      builder: (context, child) {
        return Theme(
          // Atur skema warna DatePicker di sini
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary:
                  Colors.blue[700]!, // <-- Warna header dan tanggal terpilih
              onPrimary: Colors.white, // <-- Warna teks di atas header
              onSurface: Colors.black, // <-- Warna teks tanggal di kalender
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    Colors.blue[600], // <-- Warna tombol OK dan Batal
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        // [FIX] Update text field setelah memilih
        _updateDateTextFields();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Absensi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Filter Section ---
            _buildFilterSection(),
            const SizedBox(height: 16),

            // --- Content Section (Loading, Error, List) ---
            Expanded(
              child: _buildContentSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                // [FIX] Ganti UI DatePicker menjadi TextFormField
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
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
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
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBagianDropdown(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : _fetchLaporan, // [FIX] Nonaktifkan saat loading
                icon: _isLoading
                    ? Container(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.blue[700]))
                    : const Icon(Icons.refresh),
                label: Text(_isLoading ? 'Memuat...' : 'Tampilkan Data'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [FIX] Hapus widget _buildDatePicker, sudah diganti TextFormField
  // Widget _buildDatePicker(String label, DateTime date, bool isStart) { ... }

  Widget _buildBagianDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBagian,
      isExpanded: true,
      decoration: const InputDecoration(
          labelText: 'Bagian',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      // [FIX] Tambahkan
      // Tampilkan 'Loading...' jika _bagianList masih kosong
      hint: _bagianList.isEmpty ? const Text('Loading bagian...') : null,
      items: _bagianList.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedBagian = newValue;
        });
      },
    );
  }

  Widget _buildContentSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
          child:
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_laporanData.isEmpty) {
      return const Center(
          child: Text(
              'Tidak ada data. Silakan pilih filter dan klik "Tampilkan Data".'));
    }
    return ListView.builder(
      itemCount: _laporanData.length,
      itemBuilder: (context, index) {
        final item = _laporanData[index];
        // [FIX] Logika 'isTelat' sesuai dengan data dari backend
        final bool isTelat = item['telat'] != null && item['telat'] != '-';
        final String telatText =
            isTelat ? "${item['telat']} ${item['alasan']}" : item['alasan'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['tanggal'] ?? 'No Date',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                _buildReportRow('Nama', item['nama'] ?? 'No Name'),
                _buildReportRow(
                    'Masuk', "${item['masuk']} --> ${item['scan1']}"),
                _buildReportRow(
                  'Telat',
                  telatText.trim().isEmpty
                      ? '-'
                      : telatText.trim(), // Tampilkan '-' jika kosong
                  valueColor: isTelat ? Colors.red : Colors.black87,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text('$label:', style: TextStyle(color: Colors.grey[700])),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
