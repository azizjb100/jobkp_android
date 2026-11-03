class DetAsset {
  final String jbNomor;
  final String lokasi;
  final String divisi;
  final String status; // jb_kepentingan
  final String peminta; // jb_cabang atau user peminta
  final String tglPengajuan; // jb_tanggal
  final String? keterangan; // jb_ket
  final String? jadwalPengerjaan; // jb_jadwal_pengerjaan
  final String? konfirGA;
  final String? konfirgaNama; // Nullable
  final String? jadwal1; // Nullable
  final String? jadwal2; // jb_konfir_ga
  final String? teknisi; // jb_teknisi
  final String? teknisiBantu; // jb_teknisi_bantu
  final String? konfirTeknisi; // jb_konfir_teknisi
  final String? pengajuanBarang; // jb_pengajuan_barang
  final String? sparepartGudang; // jb_sparepart_gudang
  final String? ketProses; // jb_ket_proses
  final String? selesai;
  final String? tglSelesai; // Nullable
  final String? tglClose; // Nullable
  final String user; // jb_selesai
  final String? close; // jb_close
  final String? kerusakan; // jb_kerusakan
  final String jenis; // jb_jenis
  final String? cabang; // jb_cabang
  final String bagian; // jb_bagian

  DetAsset({
    required this.jbNomor,
    required this.lokasi,
    required this.divisi,
    required this.status,
    required this.peminta,
    required this.tglPengajuan,
    this.keterangan,
    this.jadwalPengerjaan,
    this.konfirGA,
    this.konfirgaNama,
    this.jadwal1,
    this.jadwal2,
    this.teknisi,
    this.teknisiBantu,
    this.konfirTeknisi,
    this.pengajuanBarang,
    this.sparepartGudang,
    this.ketProses,
    this.selesai,
    this.close,
    this.kerusakan,
    required this.jenis,
    this.cabang,
    this.tglSelesai,
    this.tglClose,
    required this.user,
    required this.bagian,
  });

  factory DetAsset.fromJson(Map<String, dynamic> json) {
    return DetAsset(
      jbNomor: json['jb_nomor'] ?? '',
      lokasi: json['jb_lokasi'] ?? '',
      divisi: json['jb_divisi'] ?? '',
      status: json['jb_kepentingan'] ?? '',
      peminta: json['jb_cabang'] ?? '',
      tglPengajuan: json['jb_tanggal'] ?? '',
      keterangan: json['jb_ket'],
      jadwalPengerjaan: json['jb_jadwal_pengerjaan'],
      konfirGA: json['jb_konfir_ga']?.toString(),
      konfirgaNama: json['jb_konfirga_nama'], // Ini boleh null
      jadwal1: json['jb_jadwal1'], // Ini boleh null
      jadwal2: json['jb_jadwal2'],
      teknisi: json['jb_teknisi'],
      teknisiBantu: json['jb_teknisi_bantu'],
      konfirTeknisi: json['jb_konfir_teknisi'],
      pengajuanBarang: json['jb_pengajuan_barang'],
      sparepartGudang: json['jb_sparepart_gudang'],
      ketProses: json['jb_ket_proses'],
      selesai: json['jb_selesai'],
      close: json['jb_close'],
      kerusakan: json['jb_kerusakan'],
      jenis: json['jb_jenis'],
      cabang: json['jb_cabang'],
      tglSelesai: json['jb_tgl_selesai'], // Ini boleh null
      tglClose: json['jb_tgl_close'], // Ini boleh null
      user: json['jb_user'] ?? '',
      bagian: json['jb_bagian'],
    );
  }
}
