import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/finding.dart';
import 'report_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.apk});
  final File apk;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  double _uploadProgress = 0;
  String _status = 'Connecting to server…';
  bool   _error  = false;
  String _errMsg  = '';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      setState(() => _status = 'Uploading APK…');
      final result = await ApiService.instance.scanApk(
        widget.apk,
        onProgress: (p) {
          setState(() {
            _uploadProgress = p;
            if (p >= 1.0) _status = 'Decompiling and scanning…';
          });
        },
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ReportScreen(result: result)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error  = true;
        _errMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _error ? _buildError(tt, cs) : _buildProgress(tt, cs),
        ),
      ),
    );
  }

  Widget _buildProgress(TextTheme tt, ColorScheme cs) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Spacer(),
      Icon(Icons.security_rounded, size: 64, color: cs.primary),
      const SizedBox(height: 28),
      Text('Analysing APK', style: tt.headlineMedium),
      const SizedBox(height: 8),
      Text(
        widget.apk.path.split('/').last,
        style: tt.bodySmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 36),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: _uploadProgress > 0 && _uploadProgress < 1.0
              ? _uploadProgress
              : null,
          minHeight: 6,
          backgroundColor: const Color(0xFFE4DFD3),
          color: cs.primary,
        ),
      ),
      const SizedBox(height: 14),
      Text(_status, style: tt.bodyMedium),
      const Spacer(),
      Text(
        'Do not close the app.\nScanning may take up to 60 seconds.',
        style: tt.bodySmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
    ],
  );

  Widget _buildError(TextTheme tt, ColorScheme cs) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade400),
      const SizedBox(height: 24),
      Text('Scan Failed', style: tt.headlineMedium),
      const SizedBox(height: 8),
      Text(_errMsg, style: tt.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 32),
      FilledButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Go Back'),
      ),
    ],
  );
}
