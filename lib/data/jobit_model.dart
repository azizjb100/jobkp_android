class ItJob {
  final String nomor;
  final String detail;

  ItJob({
    required this.nomor,
    required this.detail,
  });

  factory ItJob.fromJson(Map<String, dynamic> json) {
    return ItJob(
      // [FIX] Sesuaikan 'key' agar cocok dengan SQL (Nomor dan detail)
      nomor: json['Nomor'] ?? '',
      detail: json['detail'] ?? '',
    );
  }
}
