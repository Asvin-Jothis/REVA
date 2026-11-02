import 'dart:io';
import 'package:dio/dio.dart';
import '../models/finding.dart';
import '../theme.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final _dio = Dio(BaseOptions(
    baseUrl: kBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
  ));

  Future<ScanResult> scanApk(
    File apk, {
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        apk.path,
        filename: apk.path.split('/').last,
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/scan',
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      return ScanResult.fromJson(response.data!);
    }
    throw Exception('Server returned ${response.statusCode}');
  }
}
