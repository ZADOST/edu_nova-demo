import 'package:flutter/material.dart';

class QrPlaceholder extends StatelessWidget {
  final double size;
  final String code;

  const QrPlaceholder({super.key, required this.size, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
      ),
      child: const Center(child: Icon(Icons.qr_code_2, size: 40, color: Colors.black54)),
    );
  }
}
