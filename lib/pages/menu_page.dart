import 'dart:async'; // [FIX] Tambahkan import
import 'dart:convert'; // [FIX] Tambahkan import
import 'package:http/http.dart' as http; // [FIX] Tambahkan import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jobkp_flutter/pages/Laporan_perbaikan_page.dart';

// Impor semua halaman tujuan menu Anda
import 'perbaikan_page.dart';
import 'pengajuan_sparepart_page.dart';
import 'menu_cs_page.dart';
import 'konfirmasi_perbaikan_page.dart';
import 'approve_realisai_sparepart_page.dart';
import 'jobit_page.dart';
import 'laporan_absen_page.dart';
import 'ganti_password_page.dart';

// Impor service manager dan notifikasi
import '../services/session_manager.dart';
import '../services/notification_service.dart'; // [FIX] Impor service notifikasi
import '../../../../config.dart'; // [FIX] Impor config

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final SessionManager _sessionManager = SessionManager();

  // [FIX] Tambahkan service notifikasi dan timer
  final NotificationService _notificationService = NotificationService();
  Timer? _notificationTimer;

  // State
  bool _isLoading = true;
  String _nama = '';
  String _divisi = '';
  String _cabang = '';
  String _userKode = '';
  int _log = 0; // zlog / user_bag
  int _manager = 0;
  int _it = 0;
  int _brg = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // [FIX] Panggil fungsi untuk memulai polling
    _startNotificationPolling();
  }

  @override
  void dispose() {
    // [FIX] Hentikan timer saat halaman ditutup
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _sessionManager.getUserData();

      // [FIX] Tambahkan cek 'mounted' setelah await
      if (!mounted) return;

      setState(() {
        _nama = userData['nama'] ?? 'User';
        _divisi = userData['divisi'] ?? '-';
        _cabang = userData['cabang'] ?? '-';
        _userKode = userData['user_kode'] ?? '';
        _log = int.tryParse(userData['user_bag']?.toString() ?? '0') ?? 0;
        _manager = int.tryParse(userData['manager']?.toString() ?? '0') ?? 0;
        _it = int.tryParse(userData['it']?.toString() ?? '0') ?? 0;
        _brg = int.tryParse(userData['brg']?.toString() ?? '0') ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print("[DEBUG] MenuPage: GAGAL memuat data user: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    _notificationTimer?.cancel(); // [FIX] Hentikan timer saat logout
    await _sessionManager.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // --- [FIX] Logika Polling Notifikasi Ditambahkan ---

  // Helper otentikasi
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _sessionManager.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan saat cek notifikasi.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  void _startNotificationPolling() {
    // Panggil sekali saat start
    _checkNotifications();

    // Panggil setiap 1 menit
    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkNotifications();
    });
  }

  Future<void> _checkNotifications() async {
    // Pastikan user sudah login sebelum cek
    if (await _sessionManager.getToken() == null) return;

    try {
      final headers = await _getAuthHeaders();
      // Panggil API backend yang kita buat
      final uri = Uri.parse('${Config.baseUrl}/notifications/check');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final List<dynamic> notifications = result['data'];

          if (notifications.isNotEmpty && mounted) {
            print("Notifikasi baru diterima: ${notifications.length}");
            for (var notif in notifications) {
              _notificationService.showNotification(
                  notif['id'] ?? 0,
                  "Update Pekerjaan", // Judul Notifikasi
                  notif['notif'] ??
                      'Anda memiliki update baru.' // Isi Notifikasi
                  );
            }
          }
        }
      }
    } catch (e) {
      print("Error saat polling notifikasi: $e");
    }
  }
  // --- Akhir Perbaikan Notifikasi ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // --- Logika Menu (Kode Anda sudah bersih dan benar) ---
    final pageCleaningService = const MenuCSPage();
    final pagePerbaikan = PerbaikanPage(
      nama: _nama,
      divisi: _divisi,
      cabang: _cabang,
      userKode: _userKode,
    );
    final pageKonfirmasiPerbaikan =
        KonfirmasiPerbaikanPage(nama: _nama, divisi: _divisi);
    final pagePengajuanSparepart = const PengajuanSparepartPage();
    final pageApproveRealisasi = const ApproveRealisasiSparepartPage();
    final pageJobIt = const JobItPage();
    final pageLaporanPerbaikan = const LaporanPerbaikanPage();
    final pageLaporanAbsen = const LaporanAbsenPage();
    final pageGantiPassword = const ChangePasswordPage();

    final bool isSuperAdmin = (_log == 9);
    final bool isIT = (_it == 1);
    final bool isManager = (_manager == 1);
    final bool isTeknisi = (_log == 2);
    final bool isUserBiasa = (_log == 0);

    final List<_MenuItem> allMenuItems = [
      _MenuItem(
        title: "Cleaning Service",
        icon: Icons.cleaning_services,
        page: (isSuperAdmin || isIT) ? pageCleaningService : null,
      ),
      _MenuItem(
        title: "Perbaikan",
        icon: Icons.build,
        page: (isSuperAdmin || isIT || isUserBiasa || isManager)
            ? pagePerbaikan
            : null,
      ),
      _MenuItem(
        title: "Konfirmasi Perbaikan",
        icon: Icons.verified,
        page: (isSuperAdmin || isIT || isManager || isTeknisi)
            ? pageKonfirmasiPerbaikan
            : null,
      ),
      _MenuItem(
        title: "Pengajuan Sparepart",
        icon: Icons.assignment,
        page: (isSuperAdmin || isIT) ? pagePengajuanSparepart : null,
      ),
      _MenuItem(
        title: "Approve Realisasi",
        icon: Icons.check_circle_outline,
        // [FIX] Diperbarui agar Teknisi juga bisa lihat
        page: (isSuperAdmin || isIT || isManager || isTeknisi || isUserBiasa)
            ? pageApproveRealisasi
            : null,
      ),
      _MenuItem(
        title: "JOB IT",
        icon: Icons.computer,
        page: (isSuperAdmin || isIT || isManager || isTeknisi || isUserBiasa)
            ? pageJobIt
            : null,
      ),
      _MenuItem(
        title: "Laporan Perbaikan",
        icon: Icons.calendar_today,
        page: (isSuperAdmin || isIT || isManager || isTeknisi || isUserBiasa)
            ? pageLaporanPerbaikan
            : null,
      ),
      _MenuItem(
        title: "Laporan Absen",
        icon: Icons.calendar_today_outlined,
        page: (isSuperAdmin || isIT) ? pageLaporanAbsen : null,
      ),
      _MenuItem(
        title: "Ganti Password",
        icon: Icons.lock_outline, // Anda bisa ganti ikonnya
        page: pageGantiPassword, // Bisa diakses semua role
      ),
    ];

    // --- UI Build ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Utama JOB KP'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      // [PERBAIKAN] Bungkus 'Column' dengan 'SafeArea'
      // Ini akan memperbaiki error 'bottom overflowed' di Android
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(_nama,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('Divisi: $_divisi'),
                  Text('Cabang: $_cabang'),
                ],
              ),
            ),

            // Konten Menu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: kIsWeb
                    ? _buildListMenu(context, allMenuItems)
                    : _buildGridMenu(context, allMenuItems),
              ),
            ),

            // Tombol Logout
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ), // [PERBAIKAN] Tutup SafeArea
    );
  }

  Widget _buildGridMenu(BuildContext context, List<_MenuItem> items) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isEnabled = item.page != null;

        return GestureDetector(
          onTap: isEnabled
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item.page!),
                  )
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Anda tidak memiliki akses ke ${item.title}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
          child: Card(
            elevation: isEnabled ? 3 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isEnabled ? Colors.white : Colors.grey.shade100,
            shadowColor: Colors.blue.shade100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon,
                    size: 40,
                    color: isEnabled
                        ? Colors.blue.shade700
                        : Colors.grey.shade400),
                const SizedBox(height: 8), // [FIX] Jarak konsisten
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? Colors.black : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListMenu(BuildContext context, List<_MenuItem> items) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isEnabled = item.page != null;

        return Card(
          elevation: isEnabled ? 2 : 1,
          color: isEnabled ? Colors.white : Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            horizontalTitleGap: 10.0, // [FIX] Jarak konsisten
            leading: Icon(item.icon,
                color: isEnabled ? Colors.blue.shade700 : Colors.grey.shade400),
            title: Text(
              item.title,
              style: TextStyle(
                color: isEnabled ? Colors.black : Colors.grey.shade500,
              ),
            ),
            onTap: isEnabled
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item.page!),
                    )
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Anda tidak memiliki akses ke ${item.title}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget? page;
  _MenuItem({required this.title, required this.icon, this.page});
}
