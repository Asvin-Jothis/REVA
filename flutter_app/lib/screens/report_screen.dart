import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/finding.dart';
import '../services/pdf_service.dart';
import '../widgets/finding_card.dart';
import '../widgets/summary_card.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.result});
  final ScanResult result;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _filter = 'ALL';
  bool   _saving = false;

  static const _order = {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3};

  List<Finding> get _filtered {
    final all = [...widget.result.findings]
      ..sort((a, b) => (_order[a.severity] ?? 4).compareTo(_order[b.severity] ?? 4));
    return _filter == 'ALL' ? all : all.where((f) => f.severity == _filter).toList();
  }

  Future<void> _downloadPdf() async {
    setState(() => _saving = true);
    try {
      final file = await PdfService.instance.generateReport(widget.result);
      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: 'REVA_${widget.result.apkName}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt     = Theme.of(context).textTheme;
    final cs     = Theme.of(context).colorScheme;
    final counts = widget.result.severityCounts;
    final total  = widget.result.findings.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Report'),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              tooltip: 'Download PDF',
              icon: const Icon(Icons.download_rounded),
              onPressed: _downloadPdf,
            ),
        ],
      ),
      body: Column(
        children: [
          // header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.result.apkName,
                    style: tt.titleMedium, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${widget.result.scannedFiles} files scanned  ·  $total finding(s)',
                  style: tt.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  SummaryCard(label: 'CRITICAL', count: counts['CRITICAL'] ?? 0, severity: 'CRITICAL'),
                  SummaryCard(label: 'HIGH',     count: counts['HIGH']     ?? 0, severity: 'HIGH'),
                  SummaryCard(label: 'MEDIUM',   count: counts['MEDIUM']   ?? 0, severity: 'MEDIUM'),
                  SummaryCard(label: 'LOW',      count: counts['LOW']      ?? 0, severity: 'LOW'),
                ]),
              ],
            ),
          ),

          // filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((sev) {
                  final active = _filter == sev;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(sev),
                      selected: active,
                      onSelected: (_) => setState(() => _filter = sev),
                      selectedColor: cs.primary.withOpacity(0.12),
                      checkmarkColor: cs.primary,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? cs.primary : const Color(0xFF565B73),
                      ),
                      side: BorderSide(
                        color: active ? cs.primary.withOpacity(0.4) : const Color(0xFFE4DFD3),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE4DFD3)),

          // findings list
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 56, color: Colors.green.shade400),
                        const SizedBox(height: 12),
                        Text(
                          total == 0
                              ? 'No vulnerabilities found!'
                              : 'No $_filter findings.',
                          style: tt.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => FindingCard(_filtered[i]),
                  ),
          ),
        ],
      ),

      // FAB download
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _downloadPdf,
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.picture_as_pdf_rounded),
        label: const Text('Download PDF'),
      ),
    );
  }
}
