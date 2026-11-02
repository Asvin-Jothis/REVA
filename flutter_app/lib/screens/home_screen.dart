import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selected;
  bool  _loading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selected = File(result.files.single.path!));
    }
  }

  Future<void> _startScan() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanScreen(apk: _selected!),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Logo + title
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.security, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REVA', style: tt.headlineMedium),
                    Text('Reverse Engineering Vulnerability Analyzer',
                        style: tt.bodySmall),
                  ],
                ),
              ]),
              const SizedBox(height: 48),
              Text('Scan an APK', style: tt.headlineLarge),
              const SizedBox(height: 6),
              Text(
                'Upload any Android APK file to analyse it for common security vulnerabilities.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Drop zone
              GestureDetector(
                onTap: _pickFile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  decoration: BoxDecoration(
                    color: _selected != null
                        ? cs.primary.withOpacity(0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selected != null
                          ? cs.primary.withOpacity(0.4)
                          : const Color(0xFFE4DFD3),
                      width: _selected != null ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selected != null
                            ? Icons.check_circle_rounded
                            : Icons.folder_open_rounded,
                        size: 48,
                        color: _selected != null
                            ? cs.primary
                            : const Color(0xFF8C8FA3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selected != null
                            ? _selected!.path.split('/').last
                            : 'Tap to select an APK file',
                        style: _selected != null
                            ? tt.titleMedium?.copyWith(color: cs.primary)
                            : tt.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (_selected != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${(_selected!.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB',
                          style: tt.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _pickFile,
                          child: const Text('Change file'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Scan button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selected == null || _loading ? null : _startScan,
                  icon: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.radar_rounded, size: 20),
                  label: Text(_loading ? 'Preparing…' : 'Scan APK'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Files are scanned on a secure backend server and never stored permanently.',
                  style: tt.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
