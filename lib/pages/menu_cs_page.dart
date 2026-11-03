import 'package:flutter/material.dart';
import 'lap_nilai_page.dart';
import 'lap_area_page.dart';

class MenuCSPage extends StatelessWidget {
  const MenuCSPage({super.key});

  Widget _buildMenuButton(BuildContext context, String title, IconData icon,
      {required VoidCallback onTap, Color? color}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color ?? Colors.blue.shade50,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue.shade700, size: 32),
              const SizedBox(width: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Cleaning Service'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildMenuButton(
              context,
              'Input Penilaian',
              Icons.assignment,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menu Input Penilaian ditekan')),
                );
              },
            ),
            _buildMenuButton(
              context,
              "Laporan Nilai",
              Icons.assignment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LapNilaiPage()),
                );
              },
            ),
            _buildMenuButton(
              context,
              "Laporan Area",
              Icons.map,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LapAreaPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
