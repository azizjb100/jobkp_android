import 'dart:async';
import 'package:flutter/material.dart';

// [PERBAIKAN] Nama class diubah dari _EmptyDataAnimation menjadi EmptyDataAnimation
// (tanpa '_') agar bisa di-import oleh file lain.

class EmptyDataAnimation extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Future<void> Function() onRefresh;

  const EmptyDataAnimation({
    super.key, // [FIX] Tambahkan super.key
    required this.title,
    required this.message,
    required this.onRefresh,
    this.icon = Icons.search_off,
    this.iconColor,
  });

  @override
  State<EmptyDataAnimation> createState() => _EmptyDataAnimationState();
}

class _EmptyDataAnimationState extends State<EmptyDataAnimation> {
  bool _isVisible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Atur timer untuk membuat animasi "berdenyut" (pulse)
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _isVisible = !_isVisible;
        });
      }
    });
    // Atur state awal setelah delay singkat
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bungkus dengan RefreshIndicator agar pengguna bisa "pull to refresh"
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      // ListView + AlwaysScrollableScrollPhysics diperlukan agar RefreshIndicator
      // berfungsi bahkan jika kontennya pas di tengah layar.
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            // Set tinggi minimal agar 'center' berfungsi
            height: MediaQuery.of(context).size.height * 0.5,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24.0),
            // Widget animasi utama
            child: AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.4, // Berdenyut antara 100% dan 40%
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon,
                      size: 80, color: widget.iconColor ?? Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
