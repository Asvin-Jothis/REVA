import 'package:flutter/material.dart';
import '../theme.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.count,
    required this.severity,
  });
  final String label;
  final int count;
  final String severity;

  @override
  Widget build(BuildContext context) {
    final col = severityColor(severity);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: col.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800, color: col,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700,
              color: Color(0xFF8C8FA3), letterSpacing: 0.4,
            ),
          ),
        ]),
      ),
    );
  }
}
