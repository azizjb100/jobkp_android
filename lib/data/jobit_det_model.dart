// File: data/it_job_detail_model.dart

class ItJobDetail {
  final String jbNomor;
  final String tanggalOnly; // Berisi '2025-10-18'
  final String userNama;
  final String jbCabang;
  final String jbLokasi;
  final String jbJenis; // 'HARDWARE' or 'SOFTWARE'
  final String jbIt; // Nama staff IT
  final String jbKet;
  final String jbNote;
  final int jbKonfirit; // 0 or 1
  final int jbSelesai; // 0, 1, or 2
  final String jbTglClose; // Berisi tanggal atau string kosong

  ItJobDetail({
    required this.jbNomor,
    required this.tanggalOnly,
    required this.userNama,
    required this.jbCabang,
    required this.jbLokasi,
    required this.jbJenis,
    required this.jbIt,
    required this.jbKet,
    required this.jbNote,
    required this.jbKonfirit,
    required this.jbSelesai,
    required this.jbTglClose,
  });

  factory ItJobDetail.fromJson(Map<String, dynamic> json) {
    // Helper untuk konversi aman ke int
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ItJobDetail(
      jbNomor: json['jb_nomor'] ?? '',
      tanggalOnly: json['tanggalOnly'] ?? '',
      userNama: json['user_nama'] ?? '',
      jbCabang: json['jb_cabang'] ?? '',
      jbLokasi: json['jb_lokasi'] ?? '',
      jbJenis: json['jb_jenis'] ?? 'HARDWARE', // Default ke HARDWARE jika null
      jbIt: json['jb_it'] ?? '',
      jbKet: json['jb_ket'] ?? '',
      jbNote: json['jb_note'] ?? '',
      jbKonfirit: parseInt(json['jb_konfirit']),
      jbSelesai: parseInt(json['jb_selesai']),
      jbTglClose: json['jb_tgl_close'] ?? '',
    );
  }
}
