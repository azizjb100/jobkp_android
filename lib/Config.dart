class Config {
  // Ambil dari --dart-define, kalau gak ada pakai default (misal localhost)
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://103.94.238.252:5000/api',
    //defaultValue: 'http://localhost:5000/api',
  );
}
