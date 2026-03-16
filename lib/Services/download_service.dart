import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static final Dio _dio = Dio();

  /// Converts a Google Drive sharing link to a direct download link if possible.
  static String? _getDirectDownloadUrl(String url) {
    if (url.contains('drive.google.com')) {
      final uri = Uri.parse(url);
      String? fileId;
      
      if (uri.path.contains('file/d/')) {
        final parts = uri.path.split('/');
        final index = parts.indexOf('d');
        if (index != -1 && index + 1 < parts.length) {
          fileId = parts[index + 1];
        }
      } else if (uri.queryParameters.containsKey('id')) {
        fileId = uri.queryParameters['id'];
      }

      if (fileId != null) {
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }
    return url;
  }

  static Future<void> downloadAndInstall({
    required String url,
    required String fileName,
    required Function(double progress) onProgress,
    required Function(String error) onError,
    required VoidCallback onComplete,
  }) async {
    try {
      String directUrl = _getDirectDownloadUrl(url) ?? url;
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';

      // 1. Initial attempt to get headers or final URL
      Response response = await _dio.get(
        directUrl,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      // 2. Handle Google Drive's "Virus Scan" confirmation page if present
      if (response.data is String && (response.data as String).contains('confirm=')) {
        final content = response.data as String;
        final regExp = RegExp(r'href="([^"]*confirm=[^"]*)"');
        final match = regExp.firstMatch(content);
        if (match != null) {
          directUrl = match.group(1)!.replaceAll('&amp;', '&');
          if (!directUrl.startsWith('http')) {
            directUrl = 'https://drive.google.com$directUrl';
          }
        }
      }

      // 3. Perform actual download
      await _dio.download(
        directUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          } else {
            onProgress(-1);
          }
        },
      );

      // No in-app installation without the plugin.
      // We will let the UI handle the completion message/action.
      onComplete();
    } catch (e) {
      debugPrint('Error downloading update: $e');
      onError(e.toString());
    }
  }
}
