import 'package:flutter/material.dart';
import '../models/finding.dart';
import '../theme.dart';
import 'severity_badge.dart';

class FindingCard extends StatefulWidget {
  const FindingCard(this.finding, {super.key});
  final Finding finding;

  @override
  State<FindingCard> createState() => _FindingCardState();
}

class _FindingCardState extends State<FindingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final f   = widget.finding;
    final col = severityColor(f.severity);
    final tt  = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE4DFD3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // top colour band
            Container(height: 3, color: col),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SeverityBadge(f.severity),
                        const SizedBox(width: 8),
                        Text(f.id,
                            style: tt.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: const Color(0xFF8C8FA3),
                            )),
                        const Spacer(),
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: const Color(0xFF8C8FA3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(f.name, style: tt.titleMedium),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 12, color: Color(0xFF8C8FA3)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${f.file}  :  line ${f.line}',
                          style: tt.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1, color: Color(0xFFE4DFD3)),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section(context, 'What is this?', f.description),
                    const SizedBox(height: 12),
                    _section(context, 'Code snippet', null),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        f.snippet,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _section(context, 'How to fix', f.fix),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext ctx, String label, String? text) {
    final tt = Theme.of(ctx).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelLarge?.copyWith(color: const Color(0xFF8C8FA3))),
        if (text != null) ...[
          const SizedBox(height: 4),
          Text(text, style: tt.bodyMedium),
        ],
      ],
    );
  }
}
