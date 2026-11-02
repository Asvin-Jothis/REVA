import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/finding.dart';

class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  static const _critical = PdfColor.fromInt(0xFFC46A7A);
  static const _high     = PdfColor.fromInt(0xFFC99A53);
  static const _medium   = PdfColor.fromInt(0xFFA88B2E);
  static const _low      = PdfColor.fromInt(0xFF6E9C82);
  static const _ink      = PdfColor.fromInt(0xFF1F2333);
  static const _muted    = PdfColor.fromInt(0xFF565B73);
  static const _panel    = PdfColor.fromInt(0xFFF4F0E6);
  static const _line     = PdfColor.fromInt(0xFFE4DFD3);

  PdfColor _sevColor(String s) {
    switch (s.toUpperCase()) {
      case 'CRITICAL': return _critical;
      case 'HIGH':     return _high;
      case 'MEDIUM':   return _medium;
      default:         return _low;
    }
  }

  Future<File> generateReport(ScanResult result) async {
    final pdf = pw.Document();
    final font     = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontMono = await PdfGoogleFonts.sourceCodeProRegular();

    final counts = result.severityCounts;
    final sorted = [...result.findings]
      ..sort((a, b) {
        const o = {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3};
        return (o[a.severity] ?? 4).compareTo(o[b.severity] ?? 4);
      });

    // ── Cover page ──────────────────────────────────────────────────────────
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('REVA', style: pw.TextStyle(font: fontBold, fontSize: 36, color: _ink)),
          pw.Text('Reverse Engineering Vulnerability Analyzer',
              style: pw.TextStyle(font: font, fontSize: 13, color: _muted)),
          pw.SizedBox(height: 4),
          pw.Divider(color: _line),
          pw.SizedBox(height: 16),
          pw.Text('Scan Report', style: pw.TextStyle(font: fontBold, fontSize: 20, color: _ink)),
          pw.SizedBox(height: 6),
          _infoRow(font, fontBold, 'Target', result.apkName),
          _infoRow(font, fontBold, 'Scanned', result.scannedAt.toLocal().toString().split('.').first),
          _infoRow(font, fontBold, 'Files', '${result.scannedFiles} files analysed'),
          _infoRow(font, fontBold, 'Total', '${result.findings.length} finding(s)'),
          pw.SizedBox(height: 20),
          // Summary table
          pw.Table(
            border: pw.TableBorder.all(color: _line, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _ink),
                children: ['Severity', 'Count'].map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(h, style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white)),
                )).toList(),
              ),
              ...['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((sev) => pw.TableRow(
                decoration: pw.BoxDecoration(color: counts[sev] == 0 ? PdfColors.white : _panel),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(sev, style: pw.TextStyle(font: fontBold, fontSize: 10, color: _sevColor(sev)))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${counts[sev] ?? 0}',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: _ink))),
                ],
              )),
            ],
          ),
          if (result.findings.isEmpty) ...[
            pw.SizedBox(height: 30),
            pw.Text('✓  No vulnerabilities detected.',
                style: pw.TextStyle(font: fontBold, fontSize: 14, color: _low)),
          ],
        ],
      ),
    ));

    // ── Findings pages ───────────────────────────────────────────────────────
    if (sorted.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => sorted.map((f) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              decoration: pw.BoxDecoration(color: _sevColor(f.severity), borderRadius: pw.BorderRadius.circular(6)),
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${f.severity}  ·  ${f.id}  ·  ${f.name}',
                      style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            _label(fontBold, font, 'File', '${f.file}  :  line ${f.line}'),
            pw.SizedBox(height: 4),
            _label(fontBold, font, 'What is it?', f.description),
            pw.SizedBox(height: 4),
            pw.Text('Code snippet', style: pw.TextStyle(font: fontBold, fontSize: 9, color: _muted)),
            pw.SizedBox(height: 2),
            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF5F5F5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(f.snippet, style: pw.TextStyle(font: fontMono, fontSize: 8, color: _muted)),
            ),
            pw.SizedBox(height: 4),
            _label(fontBold, font, 'Fix', f.fix),
            pw.SizedBox(height: 12),
            pw.Divider(color: _line, height: 1),
            pw.SizedBox(height: 12),
          ],
        )).toList(),
      ));
    }

    final dir  = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/reva_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _infoRow(pw.Font r, pw.Font b, String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(children: [
      pw.SizedBox(width: 80,
        child: pw.Text(label, style: pw.TextStyle(font: b, fontSize: 10, color: _muted))),
      pw.Text(value, style: pw.TextStyle(font: r, fontSize: 10, color: _ink)),
    ]),
  );

  pw.Widget _label(pw.Font b, pw.Font r, String label, String value) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: pw.TextStyle(font: b, fontSize: 9, color: _muted)),
      pw.Text(value, style: pw.TextStyle(font: r, fontSize: 10, color: _ink)),
    ],
  );
}
