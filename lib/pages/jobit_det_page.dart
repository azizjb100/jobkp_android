// File: pages/det_job_it_page.dart

import 'package:flutter/material.dart';

class JobItDetPage extends StatelessWidget {
  final String nomor;
  const JobItDetPage({super.key, required this.nomor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Job $nomor'),
      ),
      body: Center(
        child: Text('Ini adalah halaman detail untuk $nomor'),
      ),
    );
  }
}
