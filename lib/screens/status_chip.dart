import 'package:flutter/material.dart';

Color statusColor(String s) => switch (s) {
      'Resolved' => const Color(0xFF2E9E5B),
      'In Progress' => const Color(0xFFE0A100),
      _ => const Color(0xFFD9534F),
    };

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
