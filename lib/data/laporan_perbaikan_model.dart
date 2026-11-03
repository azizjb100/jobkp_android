// File: lib/models/laporan_perbaikan_model.dart

// Model untuk satu item di daftar laporan (hasil dari query utama)
class LaporanPerbaikanItem {
  final String nomor;
  final String detail;

  LaporanPerbaikanItem({required this.nomor, required this.detail});

  factory LaporanPerbaikanItem.fromJson(Map<String, dynamic> json) {
    return LaporanPerbaikanItem(
      nomor: json['Nomor'] ?? '',
      detail: json['Detail'] ?? '',
    );
  }
}

// Model untuk opsi filter User
class UserFilterItem {
  final String userKode;
  final String userNama;

  UserFilterItem({required this.userKode, required this.userNama});

  factory UserFilterItem.fromJson(Map<String, dynamic> json) {
    return UserFilterItem(
      userKode: json['user_kode'] ?? '',
      userNama: json['user_nama'] ?? 'Tanpa Nama',
    );
  }
}

// Model untuk opsi filter Cabang
class BranchFilterItem {
  final String kodeCabang;
  final String namaCabang;

  BranchFilterItem({required this.kodeCabang, required this.namaCabang});

  factory BranchFilterItem.fromJson(Map<String, dynamic> json) {
    return BranchFilterItem(
      kodeCabang: json['kode_cabang'] ?? '',
      namaCabang: json['nama_cabang'] ?? 'Tanpa Nama',
    );
  }
}
