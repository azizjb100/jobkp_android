class Job {
  final String nomor;
  final String tanggal;
  final String cabang;
  final String divisi;
  final String bagian;
  final String lokasi;
  final String jenis;
  final String keterangan;
  final String kepentingan;
  final String konfirGa;
  final String? konfirgaNama; // Nullable
  final String? jadwal1; // Nullable
  final String? jadwal2; // Nullable
  final String jadwalPengerjaan;
  final String teknisi;
  final String teknisiBantu;
  final String konfirTeknisi;
  final String pengajuanBarang;
  final String sparepartGudang;
  final String ketProses;
  final String statusSelesai;
  final String? tglSelesai; // Nullable
  final String? tglClose; // Nullable
  final String user;
  final String statusClose;

  Job({
    required this.nomor,
    required this.tanggal,
    required this.cabang,
    required this.divisi,
    required this.bagian,
    required this.lokasi,
    required this.jenis,
    required this.keterangan,
    required this.kepentingan,
    required this.konfirGa,
    this.konfirgaNama,
    this.jadwal1,
    this.jadwal2,
    required this.jadwalPengerjaan,
    required this.teknisi,
    required this.teknisiBantu,
    required this.konfirTeknisi,
    required this.pengajuanBarang,
    required this.sparepartGudang,
    required this.ketProses,
    required this.statusSelesai,
    this.tglSelesai,
    this.tglClose,
    required this.user,
    required this.statusClose,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      nomor: json['jb_nomor'] ?? '',
      tanggal: json['jb_tanggal'] ?? '',
      cabang: json['jb_cabang'] ?? '',
      divisi: json['jb_divisi'] ?? '',
      bagian: json['jb_bagian'] ?? '',
      lokasi: json['jb_lokasi'] ?? '',
      jenis: json['jb_jenis'] ?? '',
      keterangan: json['jb_ket'] ?? '',
      kepentingan: json['jb_kepentingan'] ?? '',
      konfirGa: json['jb_konfir_ga'] ?? '',
      konfirgaNama: json['jb_konfirga_nama'],
      jadwal1: json['jb_jadwal1'],
      jadwal2: json['jb_jadwal2'],
      jadwalPengerjaan: json['jb_jadwal_pengerjaan'] ?? '',
      teknisi: json['jb_teknisi'] ?? '',
      teknisiBantu: json['jb_teknisi_bantu'] ?? '',
      konfirTeknisi: json['jb_konfir_teknisi'] ?? '',
      pengajuanBarang: json['pengajuanBarang']?.toString() ?? '',
      sparepartGudang: json['jb_pengajuan'] ?? '',
      ketProses: json['jb_ket_teknisi'] ?? '',
      statusSelesai: json['jb_selesai'] ?? '',
      tglSelesai: json['jb_tgl_selesai'],
      tglClose: json['jb_tgl_close'],
      user: json['jb_user'] ?? '',
      statusClose: json['jb_close'] ?? '',
    );
  }
}

// Gunakan nama yang berbeda untuk detail pengajuan sparepart
class SparepartPengajuan {
  final String nama;
  final String satuan;
  final double qty;

  SparepartPengajuan({
    required this.nama,
    required this.satuan,
    required this.qty,
  });

  factory SparepartPengajuan.fromJson(Map<String, dynamic> json) {
    return SparepartPengajuan(
      nama: json['nama'] ?? '',
      satuan: json['satuan'] ?? '',
      qty: (json['qty'] != null)
          ? double.tryParse(json['qty'].toString()) ?? 0.0
          : 0.0,
    );
  }
}

// Class JobDetail Anda sudah benar, tidak ada perbaikan.
class JobDetail {
  final String nama;
  final String satuan;
  final double qty;

  JobDetail({
    required this.nama,
    required this.satuan,
    required this.qty,
  });

  factory JobDetail.fromJson(Map<String, dynamic> json) {
    return JobDetail(
      nama: json['nama'] ?? '',
      satuan: json['satuan'] ?? '',
      qty: (json['qty'] != null)
          ? double.tryParse(json['qty'].toString()) ?? 0.0
          : 0.0,
    );
  }
}

// Class JobDetailResponse Anda sudah benar, tidak ada perbaikan.
class JobDetailResponse {
  final Map<String, dynamic> header;
  final List<JobDetail> jobDetails; // ← dari "job_details"
  final List<SparepartPengajuan> sparepartDetails; // ← dari "sparepart_details"

  JobDetailResponse({
    required this.header,
    required this.jobDetails,
    required this.sparepartDetails,
  });

  factory JobDetailResponse.fromJson(Map<String, dynamic> json) {
    return JobDetailResponse(
      header: json['header'] ?? {},

      // --- job_details dari API ---
      jobDetails: (json['job_details'] as List<dynamic>? ?? [])
          .map((e) => JobDetail.fromJson(e))
          .toList(),

      // --- sparepart_details dari API ---
      sparepartDetails: (json['sparepart_details'] as List<dynamic>? ?? [])
          .map((e) => SparepartPengajuan.fromJson(e))
          .toList(),
    );
  }
}
