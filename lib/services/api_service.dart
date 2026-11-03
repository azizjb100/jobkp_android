// lib/services/api_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jobkp_flutter/data/job_model.dart';
import 'package:jobkp_flutter/data/user_login_model.dart';

import '../config.dart'; // Pastikan path ini benar
import './session_manager.dart';
import '../data/jobit_det_model.dart';
import '../data/jobit_model.dart'; // [FIX] Impor ini sekarang digunakan

class ApiService {
  static final SessionManager _sessionManager = SessionManager();
  static const String _baseUrl =
      Config.baseUrl; // e.g., 'http://192.168.1.10/api'

  // Base path untuk rute yang berbeda
  static const String _konfirmasiBasePath = '/konfirmasi';
  static const String _detAssetBasePath = '/detasset';
  static const String _perbaikanBasePath = '/perbaikan';
  static const String _itJobBasePath = '/jobit'; // [FIX] Ditambahkan

  // --- Helper Terpusat (Sudah Benar) ---

  static Future<Map<String, String>> _getAuthHeaders(
      {bool isPost = false}) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
    if (isPost) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    final dynamic body;
    try {
      body = json.decode(response.body);
    } catch (e) {
      throw Exception('Server Error: ${response.statusCode}');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body; // Sukses
    } else if (response.statusCode == 401) {
      throw Exception('Sesi habis. Silakan login ulang.');
    } else {
      throw Exception(body['message'] ??
          'Gagal memuat data. Status: ${response.statusCode}');
    }
  }

  // --- Fungsi API (Existing) ---

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    // ... (Kode Anda sudah benar)
    try {
      final uri = Uri.parse('$_baseUrl/auth/login');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'user_kode': username,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody['message'] ?? 'Login gagal');
      }
    } catch (e) {
      print('Error di ApiService.login: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getJobs(Map<String, String> filters) async {
    // ... (Kode Anda sudah benar)
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl$_konfirmasiBasePath/jobs')
          .replace(queryParameters: filters);
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      print('Error di ApiService.getJobs: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getDetAsset(String jbNomor) async {
    // ... (Kode Anda sudah benar)
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl$_konfirmasiBasePath/$jbNomor');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      print('Error di ApiService.getDetAsset: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getDetAssetList(
      Map<String, String> queryParams) async {
    // ... (Kode Anda sudah benar)
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl$_detAssetBasePath')
          .replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      print('Error di ApiService.getDetAssetList: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getTechnicians() async {
    // ... (Kode Anda sudah benar)
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl$_konfirmasiBasePath/technicians');
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      print('Error di ApiService.getTechnicians: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateJob(
      String nomor, Map<String, dynamic> payload) async {
    // ... (Kode Anda sudah benar)
    try {
      final headers = await _getAuthHeaders(isPost: true);
      final uri = Uri.parse('$_baseUrl$_konfirmasiBasePath/jobs/$nomor');
      final body = json.encode(payload);
      final response = await http
          .put(
            uri,
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      print('Error di ApiService.updateJob: $e');
      rethrow;
    }
  }

  // --- [FIX] FUNGSI BARU UNTUK IT JOB (DIGABUNG KE SINI) ---

  /// [FIX] 1. GET /api/it-jobs/form-data
  /// (Mengambil daftar nama IT untuk filter)
  static Future<List<String>> getItStaffList() async {
    try {
      final uri = Uri.parse('$_baseUrl$_itJobBasePath/it-staff');
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      // Gunakan helper
      final data = _handleResponse(response) as List<dynamic>;
      return data.map((e) => e.toString()).toList();
    } catch (e) {
      print('Error di ApiService.getItStaffList: $e');
      rethrow;
    }
  }

  /// [FIX] 2. GET /api/it-jobs
  /// (Mengambil list pekerjaan IT dengan filter)
  static Future<List<ItJob>> getAllItJobs(Map<String, String> filters) async {
    try {
      final uri = Uri.parse('$_baseUrl$_itJobBasePath')
          .replace(queryParameters: filters);
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      // Gunakan helper
      final data = _handleResponse(response) as List<dynamic>;
      return data.map((json) => ItJob.fromJson(json)).toList();
    } catch (e) {
      print('Error di ApiService.getAllItJobs: $e');
      rethrow;
    }
  }

  /// [FIX] 3. DELETE /api/it-jobs/:nomor
  static Future<String> deleteItJob(String nomor) async {
    try {
      final uri = Uri.parse('$_baseUrl$_itJobBasePath/$nomor');
      final headers = await _getAuthHeaders();
      final response = await http.delete(uri, headers: headers);

      // Gunakan helper
      final data = _handleResponse(response) as Map<String, dynamic>;
      return data['message'] ?? 'Berhasil dihapus';
    } catch (e) {
      print('Error di ApiService.deleteItJob: $e');
      rethrow;
    }
  }

  static Future<ItJobDetail> getItJobByNomor(String nomor) async {
    // <-- [FIX 1] Tipe return diubah
    try {
      final uri = Uri.parse('$_baseUrl$_itJobBasePath/$nomor');
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      final data = _handleResponse(response) as Map<String, dynamic>;
      // [FIX 2] Nama model diperbaiki (bukan JobIDetail)
      return ItJobDetail.fromJson(data);
    } catch (e) {
      print('Error di ApiService.getItJobByNomor: $e');
      rethrow;
    }
  }

  /// [BARU] 5. POST /api/it-jobs
  /// (Membuat tiket baru)
  static Future<Map<String, dynamic>> createItJob(
      Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$_baseUrl$_itJobBasePath');
      final headers = await _getAuthHeaders(isPost: true);
      final body = json.encode(payload);

      final response = await http.post(uri, headers: headers, body: body);

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      print('Error di ApiService.createItJob: $e');
      rethrow;
    }
  }

  /// [BARU] 6. PUT /api/it-jobs/:nomor
  /// (Mengupdate tiket)
  static Future<Map<String, dynamic>> updateItJob(
      String nomor, Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$_baseUrl$_itJobBasePath/$nomor');
      final headers = await _getAuthHeaders(isPost: true);
      final body = json.encode(payload);

      final response = await http.put(uri, headers: headers, body: body);

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      print('Error di ApiService.updateItJob: $e');
      rethrow;
    }
  }

  static Future<JobDetailResponse> getJobDetail(String nomor) async {
    try {
      final headers = await _getAuthHeaders();
      // Endpoint yang diasumsikan sesuai dengan Node.js/Express Anda:
      // Endpoint untuk job konfirmasi/detail job adalah '/konfirmasi/jobs/:nomor'
      final uri = Uri.parse('$_baseUrl$_konfirmasiBasePath/jobs/$nomor');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      // Menggunakan _handleResponse untuk parsing dan error handling
      final data = _handleResponse(response) as Map<String, dynamic>;

      // Mapping ke JobDetailResponse.
      // JobDetailResponse harus diimpor dan didefinisikan dengan benar.
      return JobDetailResponse.fromJson(data);
    } catch (e) {
      print('Error di ApiService.getJobDetail: $e');
      rethrow;
    }
  }

  static Future<List<UserLoginItem>> getLoginUsers() async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${Config.baseUrl}/auth/login-list');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserLoginItem.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat daftar user');
      }
    } catch (e) {
      print('Error di ApiService.getLoginUsers: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    try {
      final headers = await _getAuthHeaders(isPost: true); // Butuh token auth
      final uri = Uri.parse('$_baseUrl/password/change'); // Sesuaikan rute

      final body = json.encode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });

      final response = await http
          .put(
            uri,
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      print('Error di ApiService.changePassword: $e');
      rethrow;
    }
  }
  // --- [FIX] FUNGSI DUPLIKAT DIHAPUS ---
  // Kode getAuthHeaders(), getItStaffList(), getAllJobs(), deleteJob()
  // yang tidak static dan terduplikat di bagian bawah telah dihapus.

  // --- Fungsi Dummy (Disimpan agar tidak error di halaman lain) ---

  static Future<List<String>> getPenanggungJawab() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ['PJ001 - Budi', 'PJ002 - Andi', 'PJ003 - Sari'];
  }

  static Future<List<String>> getAreaByJawab(String jawab) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (jawab.contains('Budi')) return ['A001 - Lobby', 'A002 - Toilet'];
    if (jawab.contains('Andi')) return ['A003 - Kantor Depan'];
    return ['A004 - Gudang'];
  }

  static Future<List<String>> getLaporan({
    required String jawab,
    required String area,
    required String tanggal,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      '$jawab: $area = Bersih - 08:30:12',
      '$jawab: $area = Sedang - 10:12:45',
    ];
  }

  static Future<List<String>> getStatusPekerjaan() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ['Semua', 'Belum Selesai', 'Selesai'];
  }
}
