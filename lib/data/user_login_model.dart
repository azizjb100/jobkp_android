class UserLoginItem {
  final String userKode;
  final String userNama;
  final String password;

  UserLoginItem(
      {required this.userKode, required this.userNama, required this.password});

  factory UserLoginItem.fromJson(Map<String, dynamic> json) {
    return UserLoginItem(
      userKode: json['user_kode'] ?? '',
      userNama: json['user_nama'] ?? '',
      password: json['password'] ?? '',
    );
  }
}
