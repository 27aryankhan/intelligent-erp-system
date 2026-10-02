import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class AppUpdateInfo {
  final String latestVersion;
  final int latestVersionCode;
  final int minSupportedVersionCode;
  final String downloadUrl;
  final List<String> releaseNotes;
  final bool isCritical;

  AppUpdateInfo({
    required this.latestVersion,
    required this.latestVersionCode,
    required this.minSupportedVersionCode,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isCritical,
  });

  bool get hasUpdate => latestVersionCode > UpdateService.currentVersionCode;
  bool get isMandatory => isCritical || (UpdateService.currentVersionCode < minSupportedVersionCode);

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    List<String> notes = [];
    if (json['release_notes'] is List) {
      notes = (json['release_notes'] as List).map((e) => e.toString()).toList();
    } else if (json['release_notes'] is String) {
      notes = [json['release_notes'].toString()];
    }

    return AppUpdateInfo(
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
      latestVersionCode: int.tryParse(json['version_code']?.toString() ?? '1') ?? 1,
      minSupportedVersionCode: int.tryParse(json['min_supported_version_code']?.toString() ?? '1') ?? 1,
      downloadUrl: json['download_url']?.toString() ?? 'https://github.com/bhargavi-builds/intelligent-erp-system/releases/latest',
      releaseNotes: notes,
      isCritical: json['is_critical'] == true,
    );
  }
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Current running version of the app (matches pubspec.yaml version 1.0.2+3)
  static const String currentVersion = '1.0.2';
  static const int currentVersionCode = 3;

  /// Primary 100% Free CDN URL on GitHub
  static const String primaryUpdateUrl =
      'https://raw.githubusercontent.com/bhargavi-builds/intelligent-erp-system/main/version.json';

  bool _hasPromptedThisSession = false;

  /// Check whether an update is available on the remote server
  Future<AppUpdateInfo?> checkForUpdate() async {
    final client = http.Client();
    try {
      // 1. Try Primary GitHub Raw endpoint
      try {
        final res = await client
            .get(Uri.parse(primaryUpdateUrl))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
          final data = jsonDecode(res.body);
          if (data is Map<String, dynamic>) {
            return AppUpdateInfo.fromJson(data);
          }
        }
      } catch (_) {
        // Fallback to secondary endpoint
      }

      // 2. Try Secondary Cloud Backend endpoint
      try {
        final secondaryUrl = '${ApiConfig.baseUrl}/version.json';
        final res = await client
            .get(Uri.parse(secondaryUrl))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
          final data = jsonDecode(res.body);
          if (data is Map<String, dynamic>) {
            return AppUpdateInfo.fromJson(data);
          }
        }
      } catch (_) {}

      return null;
    } finally {
      client.close();
    }
  }

  /// Automatically prompt user if an update is available
  Future<void> promptUpdateIfAvailable(
    BuildContext context, {
    bool silent = true,
  }) async {
    if (silent && _hasPromptedThisSession) return;

    final updateInfo = await checkForUpdate();

    if (!context.mounted) return;

    if (updateInfo != null && updateInfo.hasUpdate) {
      _hasPromptedThisSession = true;
      showUpdateDialog(context, updateInfo);
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
              SizedBox(width: 10),
              Text('Your Intelligent ERP is up to date! (v1.0.0)'),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// Launches the download URL in the device browser / download manager
  Future<bool> launchDownload(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching update URL: $e');
      return false;
    }
  }

  /// Displays the modern update notification dialog
  void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !info.isMandatory,
      builder: (ctx) {
        return PopScope(
          canPop: !info.isMandatory,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: const Color(0xFF0F172A),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Color(0xFF38BDF8),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v$currentVersion ➔ v${info.latestVersion}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A new version of Intelligent ERP is ready with latest fixes and improvements:',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (info.releaseNotes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: info.releaseNotes.map((note) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (info.isMandatory) ...[
                    const SizedBox(height: 10),
                    const Text(
                      '⚠️ This update contains critical changes and is required to continue.',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!info.isMandatory)
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Later',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () {
                  launchDownload(info.downloadUrl);
                  if (!info.isMandatory) {
                    Navigator.of(ctx).pop();
                  }
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Update Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
