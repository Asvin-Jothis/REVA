class Finding {
  final String id;
  final String name;
  final String severity;
  final String file;
  final int line;
  final String snippet;
  final String description;
  final String fix;

  const Finding({
    required this.id,
    required this.name,
    required this.severity,
    required this.file,
    required this.line,
    required this.snippet,
    required this.description,
    required this.fix,
  });

  factory Finding.fromJson(Map<String, dynamic> j) => Finding(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        severity: j['severity'] ?? 'LOW',
        file: j['file'] ?? '',
        line: j['line'] ?? 0,
        snippet: j['snippet'] ?? '',
        description: j['description'] ?? '',
        fix: j['fix'] ?? '',
      );
}

class ScanResult {
  final String apkName;
  final List<Finding> findings;
  final int scannedFiles;
  final DateTime scannedAt;

  const ScanResult({
    required this.apkName,
    required this.findings,
    required this.scannedFiles,
    required this.scannedAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> j) => ScanResult(
        apkName: j['apk_name'] ?? '',
        findings: (j['findings'] as List<dynamic>? ?? [])
            .map((e) => Finding.fromJson(e as Map<String, dynamic>))
            .toList(),
        scannedFiles: j['scanned_files'] ?? 0,
        scannedAt: DateTime.tryParse(j['scanned_at'] ?? '') ?? DateTime.now(),
      );

  Map<String, int> get severityCounts {
    final counts = {'CRITICAL': 0, 'HIGH': 0, 'MEDIUM': 0, 'LOW': 0};
    for (final f in findings) {
      counts[f.severity] = (counts[f.severity] ?? 0) + 1;
    }
    return counts;
  }
}
