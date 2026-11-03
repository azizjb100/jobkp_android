import 'package:flutter/material.dart';

class DetPengajuanPage extends StatelessWidget {
  final String nomor;
  const DetPengajuanPage({super.key, required this.nomor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detail: $nomor"),
      ),
      body: Center(
        child: Text("Halaman detail untuk nomor pengajuan:\n$nomor"),
      ),
    );
  }
}
