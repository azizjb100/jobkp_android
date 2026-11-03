class Technician {
  final String kode;
  final String nama;

  Technician({
    required this.kode,
    required this.nama,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      kode: json['user_kode'] ?? '',
      nama: json['user_nama'] ?? '',
    );
  }
}
