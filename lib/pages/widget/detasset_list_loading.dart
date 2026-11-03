import 'package:flutter/material.dart';

class DetAssetListLoading extends StatelessWidget {
  const DetAssetListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.grey),
            title: Container(height: 14, color: Colors.grey.shade300),
            subtitle: Container(
              margin: const EdgeInsets.only(top: 6),
              height: 12,
              color: Colors.grey.shade200,
            ),
          ),
        );
      },
    );
  }
}
