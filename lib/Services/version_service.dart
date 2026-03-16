import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:msloyalty/Helpers/update_dialog.dart';

class AppVersion {
  final String versionCode;
  final int buildNumber;
  final String? releaseNotes;
  final String? androidUrl;
  final String? iosUrl;
  final String? windowsUrl;
  final bool isMandatory;

  AppVersion({
    required this.versionCode,
    required this.buildNumber,
    this.releaseNotes,
    this.androidUrl,
    this.iosUrl,
    this.windowsUrl,
    this.isMandatory = false,
  });

  factory AppVersion.fromMap(Map<String, dynamic> map) {
    return AppVersion(
      versionCode: map['version_code'],
      buildNumber: map['build_number'],
      releaseNotes: map['release_notes'],
      androidUrl: map['android_url'],
      iosUrl: map['ios_url'],
      windowsUrl: map['windows_url'],
      isMandatory: map['is_mandatory'] ?? false,
    );
  }
}

class VersionService {
  static final _supabase = Supabase.instance.client;

  static Future<AppVersion?> getLatestVersion() async {
    try {
      final data = await _supabase
          .from('app_versions')
          .select()
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return AppVersion.fromMap(data);
    } catch (e) {
      debugPrint('Error fetching latest version: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> checkUpdate() async {
    final latest = await getLatestVersion();
    if (latest == null) return {'available': false};

    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    
    debugPrint('Current Build: $currentBuildNumber, Latest Build: ${latest.buildNumber}');

    return {
      'available': latest.buildNumber > currentBuildNumber,
      'version': latest,
    };
  }

  static Future<void> checkVersionAndShowDialog(BuildContext context) async {
    final result = await checkUpdate();
    if (result['available'] == true) {
      if (context.mounted) {
        UpdateDialog.show(context, result['version'] as AppVersion);
      }
    }
  }
}
