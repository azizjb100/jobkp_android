import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../data/user_login_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final SessionManager _sessionManager = SessionManager();
  bool isLoading = false;
  String? errorMessage;

  static const String _lastUsernameKey = 'lastUsername';
  static const String _lastPasswordKey = 'lastPassword';

  @override
  void initState() {
    super.initState();
    _loadLastLogin();
  }

  Future<void> _loadLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUsername = prefs.getString(_lastUsernameKey);
      final lastPassword = prefs.getString(_lastPasswordKey);

      if (lastUsername != null && mounted) {
        setState(() {
          usernameController.text = lastUsername;
          // Kami hanya mengisi password jika ada, tapi hati-hati:
          // Menyimpan password di SharedPreferences tidak disarankan untuk aplikasi sensitif.
          if (lastPassword != null) {
            passwordController.text = lastPassword;
          }
        });
      }
    } catch (e) {
      print('[DEBUG] Gagal memuat data login terakhir: $e');
    }
  }

  // --- FUNGSI BARU: SIMPAN DATA LOGIN TERAKHIR ---
  Future<void> _saveLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUsernameKey, usernameController.text);
      await prefs.setString(_lastPasswordKey, passwordController.text);
    } catch (e) {
      print('[DEBUG] Gagal menyimpan data login terakhir: $e');
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.login(
        usernameController.text,
        passwordController.text,
      );

      print('[DEBUG] Response dari server: $response');

      if (response['token'] != null && response['user'] != null) {
        print(
            '[DEBUG] Login SUKSES, token ditemukan. Mencoba menyimpan sesi...');

        await _sessionManager.createSession(response);

        // <<< PANGGIL FUNGSI SIMPAN DI SINI >>>
        await _saveLastLogin();
        // <<< =========================== >>>

        print('[DEBUG] Sesi BERHASIL disimpan. Menavigasi ke /menu...');

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/menu', (route) => false);
        }
        print('[DEBUG] Perintah navigasi telah dieksekusi.');
      } else {
        print(
            '[DEBUG] Login GAGAL, token atau user tidak ditemukan di response.');
        setState(() => errorMessage =
            response['message'] ?? "Login gagal, periksa username/password");
      }
    } catch (e, stackTrace) {
      print('[DEBUG] Terjadi ERROR di blok try-catch: $e');
      print('[DEBUG] Stack Trace: $stackTrace');
      setState(() => errorMessage = "Terjadi kesalahan: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Fungsi untuk membuka dialog pencarian
  Future<void> _openUserLookupDialog() async {
    // Panggil dialog baru
    final UserLoginItem? selectedUser = await showDialog<UserLoginItem>(
      context: context,
      builder: (BuildContext context) => const _UserLookupDialog(),
    );

    // Jika user memilih salah satu, isi field
    if (selectedUser != null && mounted) {
      setState(() {
        usernameController.text = selectedUser.userKode;
        passwordController.text = selectedUser.password;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              Colors.blue.shade200,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenSize.height),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              // ==============================================================
              // MULAI MODIFIKASI DARI SINI
              // ==============================================================
              child: Column(
                // 1. Atur agar ada ruang ATAS (form) dan BAWAH (logo)
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. KUMPULKAN SEMUA FORM KE DALAM SATU COLUMN BARU
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Padding atas agar form tidak terlalu mepet
                      SizedBox(height: screenSize.height * 0.1),

                      Text(
                        'JobKP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      Text(
                        'Selamat Datang Kembali',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                      const SizedBox(height: 50),

                      // TextField Username (Kode Anda)
                      TextField(
                        controller: usernameController,
                        decoration: _buildInputDecoration(
                          hint: 'Username',
                          icon: Icons.person_outline,
                          suffixIcon: IconButton(
                            icon:
                                Icon(Icons.search, color: Colors.blue.shade700),
                            onPressed: _openUserLookupDialog,
                            tooltip: "Cari User (Debug)",
                          ),
                        ),
                        style: TextStyle(color: Colors.blueGrey.shade900),
                      ),
                      const SizedBox(height: 20),

                      // Input field Password (Kode Anda)
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: _buildInputDecoration(
                          hint: 'Password',
                          icon: Icons.lock_outline,
                        ),
                        style: TextStyle(color: Colors.blueGrey.shade900),
                      ),
                      const SizedBox(height: 35),

                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),

                      if (isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                    ],
                  ), // AKHIR DARI COLUMN FORM

                  // 3. LOGO SEBAGAI ANAK KEDUA DARI COLUMN UTAMA
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
                    child: Image.asset(
                      'assets/images/logo_kencana.png', // Pastikan path benar
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              // ==============================================================
              // AKHIR MODIFIKASI
              // ==============================================================
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: Colors.blue.shade700,
      ),
      suffixIcon: suffixIcon,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.blueGrey.shade400),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: Colors.blue.shade500,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }
}

//==============================================================================
// [PERBAIKAN] Class Dialog Pencarian User
//==============================================================================
class _UserLookupDialog extends StatefulWidget {
  const _UserLookupDialog();
  @override
  State<_UserLookupDialog> createState() => _UserLookupDialogState();
}

class _UserLookupDialogState extends State<_UserLookupDialog> {
  bool _isLoading = true;
  List<UserLoginItem> _userList = [];
  List<UserLoginItem> _filteredList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi ini memanggil API TANPA TOKEN
  Future<void> _fetchUsers() async {
    try {
      // Panggil endpoint debug /api/auth/login-list
      final uri = Uri.parse('${Config.baseUrl}/auth/login-list');
      // Panggil http.get biasa tanpa header auth
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          // Gunakan model UserLoginItem yang sudah diperbarui
          _userList = data.map((item) => UserLoginItem.fromJson(item)).toList();
          _filteredList = _userList;
          _isLoading = false;
        });
      } else {
        throw Exception(
            'Gagal memuat list user. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        Navigator.pop(context); // Tutup dialog jika error
      }
    }
  }

  // [PERBAIKAN 1] Perbarui fungsi filter agar bisa mencari berdasarkan NAMA
  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = _userList.where((user) {
        // Cari berdasarkan NAMA atau KODE
        final nama = user.userNama.toLowerCase();
        final kode = user.userKode.toLowerCase();
        return nama.contains(query) || kode.contains(query);
      }).toList();
    });
  }

  void _selectUser(UserLoginItem user) {
    // Fungsi ini sudah benar.
    // Ia mengembalikan seluruh objek (termasuk kode dan password)
    Navigator.pop(context, user);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih User (Debug)'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7, // Batasi tinggi
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    labelText: 'Cari Nama User',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder()),
                autofocus: true),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredList.isEmpty
                      ? const Center(child: Text('User tidak ditemukan.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final user = _filteredList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                // [PERBAIKAN 2] Tampilkan NAMA di title
                                title: Text(user.userNama),
                                // [PERBAIKAN 3] Tampilkan KODE di subtitle
                                subtitle: Text(user.userKode),
                                onTap: () => _selectUser(user),
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
