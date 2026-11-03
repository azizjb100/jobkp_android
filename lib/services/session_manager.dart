import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  final _storage = const FlutterSecureStorage();

  // Kunci-kunci penyimpanan
  static const _keyToken = 'jwt_token';
  static const _keyUserKode = 'user_kode';
  static const _keyNama = 'user_nama';
  static const _keyDivisi = 'user_divisi';
  static const _keyCabang = 'user_cabang';
  static const _keyUserBag = 'user_bag'; // Ini adalah role (zlog)
  static const _keyManager = 'manager';
  static const _keyIT = 'it';
  static const _keyBrg = 'brg';
  static const _keytTeknisi = 'kode_teknisi';

  /// Menyimpan data sesi setelah login berhasil
  Future<void> createSession(Map<String, dynamic> loginData) async {
    final user = loginData['user'] as Map<String, dynamic>?;
    final token = loginData['token'] as String?;

    if (user == null || token == null) {
      throw Exception('Data login tidak valid dari server.');
    }

    // [PERBAIKAN] Ganti key agar cocok dengan JSON dari backend
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(
        key: _keyUserKode, value: user['user_kode']?.toString() ?? '');
    await _storage.write(
        key: _keyNama, value: user['nama']?.toString() ?? ''); // <-- FIX
    await _storage.write(
        key: _keyDivisi, value: user['divisi']?.toString() ?? ''); // <-- FIX
    await _storage.write(
        key: _keyCabang, value: user['cabang']?.toString() ?? ''); // <-- FIX
    await _storage.write(
        key: _keyUserBag, value: user['user_bag']?.toString() ?? '0');
    await _storage.write(
        key: _keyManager, value: user['manager']?.toString() ?? '0'); // <-- FIX
    await _storage.write(
        key: _keyIT, value: user['it']?.toString() ?? '0'); // <-- FIX
    await _storage.write(
        key: _keyBrg, value: user['brg']?.toString() ?? '0'); // <-- FIX

    // [PERBAIKAN] Menyimpan kode_teknisi
    // (Pastikan backend Anda juga mengirim 'kode_teknisi' jika ada)
    await _storage.write(
        key: _keytTeknisi, value: user['kode_teknisi']?.toString() ?? '');
  }

  /// Mengambil semua data user yang tersimpan
  Future<Map<String, String?>> getUserData() async {
    return {
      'token': await _storage.read(key: _keyToken),
      'user_kode': await _storage.read(key: _keyUserKode),
      'nama': await _storage.read(key: _keyNama),
      'divisi': await _storage.read(key: _keyDivisi),
      'cabang': await _storage.read(key: _keyCabang),
      'user_bag': await _storage.read(key: _keyUserBag),
      'manager': await _storage.read(key: _keyManager),
      'it': await _storage.read(key: _keyIT),
      'brg': await _storage.read(key: _keyBrg),
      'kode_teknisi': await _storage.read(key: _keytTeknisi),
    };
  }

  /// Mengambil role (user_bag) sebagai integer
  Future<int> getRole() async {
    final roleString = await _storage.read(key: _keyUserBag);
    return int.tryParse(roleString ?? '0') ?? 0;
  }

  /// Mengambil kode teknisi
  Future<String?> getTechnicianCode() async {
    return await _storage.read(key: _keytTeknisi);
  }

  /// Mengambil kode cabang
  Future<String?> getBranchCode() async {
    return await _storage.read(key: _keyCabang);
  }

  // --- PENAMBAHAN METHOD BARU ---
  /// Mengambil user_kode (untuk fallback teknisi)
  Future<String?> getUserKode() async {
    return await _storage.read(key: _keyUserKode);
  }

  /// Mengambil divisi
  Future<String?> getDivisi() async {
    return await _storage.read(key: _keyDivisi);
  }

  Future<String?> getToken() async => await _storage.read(key: _keyToken);
  Future<void> logout() async => await _storage.deleteAll();
}
