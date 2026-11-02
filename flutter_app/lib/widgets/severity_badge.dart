import 'package:flutter/material.dart';
import '../theme.dart';

class SeverityBadge extends StatelessWidget {
  const SeverityBadge(this.severity, {super.key, this.small = false});
  final String severity;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = severityColor(severity);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical:  small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        severity,
        style: TextStyle(
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
