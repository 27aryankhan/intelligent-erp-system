import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:ota_update/ota_update.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';
import '../widgets/animated_rays.dart';
export '../widgets/animated_rays.dart';

class AppUpdateInfo {
  final String latestVersion;
  final int latestVersionCode;
  final int minSupportedVersionCode;
  final String downloadUrl;
  final String fileSize;
  final List<String> releaseNotes;
  final bool isCritical;

  AppUpdateInfo({
    required this.latestVersion,
    required this.latestVersionCode,
    required this.minSupportedVersionCode,
    required this.downloadUrl,
    this.fileSize = '21 MB',
    required this.releaseNotes,
    required this.isCritical,
  });

  bool get hasUpdate => latestVersionCode > UpdateService.effectiveVersionCode;
  // All updates are mandatory to ensure all user devices stay on the latest version
  bool get isMandatory => true;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    List<String> notes = [];
    if (json['release_notes'] is List) {
      notes =
          (json['release_notes'] as List).map((e) => e.toString()).toList();
    } else if (json['release_notes'] is String) {
      notes = [json['release_notes'].toString()];
    }

    return AppUpdateInfo(
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
      latestVersionCode:
          int.tryParse(json['version_code']?.toString() ?? '1') ?? 1,
      minSupportedVersionCode:
          int.tryParse(json['min_supported_version_code']?.toString() ?? '1') ??
              1,
      downloadUrl: json['download_url']?.toString() ??
          'https://github.com/27aryankhan/intelligent-erp-system/releases/latest/download/Intelligent.ERP.apk',
      fileSize: json['file_size']?.toString() ?? '21 MB',
      releaseNotes: notes,
      isCritical: json['is_critical'] == true,
    );
  }
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Current running version of the app (matches pubspec.yaml version 1.2.4+17)
  static const String currentVersion = '1.2.4';
  static const int currentVersionCode = 17;

  static int get effectiveVersionCode => currentVersionCode;

  /// Primary 100% Free CDN URL on GitHub
  static const String primaryUpdateUrl =
      'https://raw.githubusercontent.com/27aryankhan/intelligent-erp-system/main/version.json';

  bool _hasPromptedThisSession = false;

  /// Check whether an update is available on the remote server
  Future<AppUpdateInfo?> checkForUpdate() async {
    final client = http.Client();
    try {
      // 1. Try Primary GitHub Raw endpoint
      try {
        final cacheBusterUrl =
            '$primaryUpdateUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        final res = await client
            .get(Uri.parse(cacheBusterUrl))
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
        final secondaryUrl =
            '${ApiConfig.baseUrl}/version.json?t=${DateTime.now().millisecondsSinceEpoch}';
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

      // 3. Try Dedicated Cloud Backend API route
      try {
        final apiUrl =
            '${ApiConfig.baseUrl}/api/update?current_code=$effectiveVersionCode&t=${DateTime.now().millisecondsSinceEpoch}';
        final res = await client
            .get(Uri.parse(apiUrl))
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
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Intelligent ERP is up to date (v$currentVersion).',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// Resolves the direct download URL for APK
  static String resolveDirectDownloadUrl(String url) {
    if (url.endsWith('.apk')) return url;
    if (url.contains('github.com') && url.contains('/releases')) {
      return 'https://github.com/27aryankhan/intelligent-erp-system/releases/latest/download/Intelligent.ERP.apk';
    }
    return url;
  }

  /// Displays the modern in-app update notification dialog
  void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !info.isMandatory,
      builder: (ctx) => _InAppUpdateDialog(info: info),
    );
  }

  /// Displays the update dialog in preview mode for UI & UX testing
  void showTestPreviewDialog(BuildContext context) {
    final previewInfo = AppUpdateInfo(
      latestVersion: '1.2.1',
      latestVersionCode: 14,
      minSupportedVersionCode: 11,
      downloadUrl:
          'https://github.com/27aryankhan/intelligent-erp-system/releases/latest/download/Intelligent.ERP.apk',
      fileSize: '40 MB',
      releaseNotes: const [
        'Autonomous Background & Killed-App Notifications: Receive updates even when the app is closed or minimized',
        'Faculty-Specific Real-Time Attendance Alerts: Details Subject, Faculty Name, and Present/Absent status with live percentage',
        'Daily Evening Attendance Summary: End-of-day report with classes conducted, attended, missed, and aggregate percentage',
        'Timetable Period & Class Reminders: 10-minute alerts before each scheduled lecture with timing and faculty info',
        'Persistent User Session: Safe credential storage keeps users logged in until explicit logout',
        'Pixel Run Mini-Game: Autonomous continuous runner integrated directly on the student dashboard',
        'Optimized mobile APK build (~40 MB) for physical devices (armeabi-v7a & arm64-v8a)',
      ],
      isCritical: false,
    );
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _InAppUpdateDialog(info: previewInfo),
    );
  }
}

// AnimatedRays is exported from package:intelligent_erp/widgets/animated_rays.dart


class _InAppUpdateDialog extends StatefulWidget {
  final AppUpdateInfo info;

  const _InAppUpdateDialog({required this.info});

  @override
  State<_InAppUpdateDialog> createState() => _InAppUpdateDialogState();
}

class _InAppUpdateDialogState extends State<_InAppUpdateDialog> {
  bool _isDownloading = false;
  bool _isComplete = false;
  String? _downloadError;
  String? _installError;
  double _progress = 0.0;
  String _downloadedSize = '0.0 MB';
  String _totalSize = '40.0 MB';
  String _speedText = '';
  String _etaText = '';
  String? _downloadedFilePath;
  http.Client? _activeClient;
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void initState() {
    super.initState();
    _totalSize = widget.info.fileSize;
    _checkExistingApk();
  }

  double _parseExpectedTotalMb() {
    final match = RegExp(r'([\d\.]+)').firstMatch(widget.info.fileSize);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '40.0') ?? 40.0;
    }
    return 40.0;
  }

  /// If the APK was already downloaded in cache, offer instant installation
  Future<void> _checkExistingApk() async {
    try {
      Directory? saveDir;
      if (Platform.isAndroid) {
        final extDirs = await getExternalCacheDirectories();
        if (extDirs != null && extDirs.isNotEmpty) {
          saveDir = extDirs.first;
        }
      }
      saveDir ??= await getTemporaryDirectory();
      final saveFile = File(p.join(saveDir.path, 'Intelligent_ERP_Update.apk'));
      if (await saveFile.exists() && await saveFile.length() > 5 * 1024 * 1024) {
        if (mounted) {
          setState(() {
            _downloadedFilePath = saveFile.path;
            _isComplete = true;
            _progress = 1.0;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _otaSubscription?.cancel();
    _activeClient?.close();
    super.dispose();
  }

  Future<void> _startInAppDownload() async {
    final expectedMb = _parseExpectedTotalMb();
    setState(() {
      _isDownloading = true;
      _isComplete = false;
      _downloadError = null;
      _installError = null;
      _progress = 0.0;
      _downloadedSize = '0.0 MB';
      _totalSize = '${expectedMb.toStringAsFixed(1)} MB';
      _speedText = 'Connecting...';
      _etaText = '';
    });

    final targetUrl =
        UpdateService.resolveDirectDownloadUrl(widget.info.downloadUrl);

    // Primary: Android Background OTA Service
    if (Platform.isAndroid) {
      try {
        _otaSubscription?.cancel();
        _otaSubscription = OtaUpdate().execute(
          targetUrl,
          destinationFilename: 'Intelligent_ERP_Update.apk',
        ).listen(
          (OtaEvent event) {
            if (!mounted) return;
            debugPrint('OTA Status: ${event.status}, Value: ${event.value}');
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                final int progInt = int.tryParse(event.value ?? '0') ?? 0;
                final double prog = (progInt / 100.0).clamp(0.0, 0.99);
                final double totalMbVal = expectedMb;
                final double dlMbVal = totalMbVal * prog;
                setState(() {
                  _isDownloading = true;
                  _isComplete = false;
                  _progress = prog;
                  _downloadedSize = '${dlMbVal.toStringAsFixed(1)} MB';
                  _totalSize = '${totalMbVal.toStringAsFixed(1)} MB';
                  _speedText = 'OTA Service';
                });
                break;
              case OtaStatus.INSTALLING:
              case OtaStatus.INSTALLATION_DONE:
                setState(() {
                  _isDownloading = false;
                  _isComplete = true;
                  _progress = 1.0;
                  _speedText = '';
                });
                break;
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                setState(() {
                  _isDownloading = false;
                  _installError =
                      'Permission Needed: Please enable "Install unknown apps" for Intelligent ERP in Android Settings, then tap Update Now.';
                });
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                setState(() {
                  _isDownloading = true;
                });
                break;
              case OtaStatus.DOWNLOAD_ERROR:
              case OtaStatus.INTERNAL_ERROR:
              case OtaStatus.CHECKSUM_ERROR:
              case OtaStatus.INSTALLATION_ERROR:
                setState(() {
                  _isDownloading = false;
                  _downloadError =
                      event.value ?? 'Download failed. Please tap retry.';
                });
                break;
              case OtaStatus.CANCELED:
                setState(() {
                  _isDownloading = false;
                  _downloadError = 'Download cancelled';
                });
                break;
            }
          },
          onError: (e) {
            if (!mounted) return;
            setState(() {
              _isDownloading = false;
              _downloadError = e.toString().replaceAll('Exception: ', '');
            });
          },
        );
        return;
      } catch (e) {
        debugPrint('OtaUpdate exception, falling back to direct stream: $e');
      }
    }

    // Fallback: Direct streamed client
    final client = http.Client();
    _activeClient = client;

    try {
      http.StreamedResponse? streamedResponse;
      int redirectHops = 0;
      String currentUrl = targetUrl;

      // Robustly follow redirects across CDNs
      while (redirectHops < 8) {
        final request = http.Request('GET', Uri.parse(currentUrl));
        request.followRedirects = true;
        request.maxRedirects = 8;

        final res = await client.send(request);
        if (res.statusCode >= 300 &&
            res.statusCode < 400 &&
            res.headers.containsKey('location')) {
          currentUrl = res.headers['location']!;
          redirectHops++;
          continue;
        }

        streamedResponse = res;
        break;
      }

      if (streamedResponse == null || streamedResponse.statusCode != 200) {
        throw Exception(
            'Server responded with HTTP ${streamedResponse?.statusCode ?? "error"}');
      }

      final int? reportedLength = streamedResponse.contentLength;
      final int totalBytes = (reportedLength != null && reportedLength > 0)
          ? reportedLength
          : (expectedMb * 1024 * 1024).round();

      Directory? saveDir;
      if (Platform.isAndroid) {
        try {
          final extDirs = await getExternalCacheDirectories();
          if (extDirs != null && extDirs.isNotEmpty) {
            saveDir = extDirs.first;
          }
        } catch (_) {}
      }
      saveDir ??= await getTemporaryDirectory();

      final saveFile = File(p.join(saveDir.path, 'Intelligent_ERP_Update.apk'));
      if (await saveFile.exists()) {
        try {
          await saveFile.delete();
        } catch (_) {}
      }

      final sink = saveFile.openWrite();
      int receivedBytes = 0;
      final stopwatch = Stopwatch()..start();
      int lastSampleBytes = 0;
      int lastSampleTimeMs = 0;
      double currentSpeedBytesPerSec = 0;

      final chunkStream = streamedResponse.stream.timeout(
        const Duration(seconds: 15),
        onTimeout: (sink) {
          sink.addError(TimeoutException(
              'Connection timed out while receiving update package. Please retry.'));
        },
      );

      await for (final chunk in chunkStream) {
        if (!mounted) break;
        sink.add(chunk);
        receivedBytes += chunk.length;

        final elapsedMs = stopwatch.elapsedMilliseconds;
        if (elapsedMs - lastSampleTimeMs >= 350) {
          final timeDeltaSec = (elapsedMs - lastSampleTimeMs) / 1000.0;
          final bytesDelta = receivedBytes - lastSampleBytes;
          currentSpeedBytesPerSec = bytesDelta / timeDeltaSec;

          lastSampleBytes = receivedBytes;
          lastSampleTimeMs = elapsedMs;
        }

        double prog = 0.0;
        if (totalBytes > 0) {
          final raw = receivedBytes / totalBytes;
          prog = raw >= 1.0 ? 0.95 : raw.clamp(0.0, 0.95);
        }

        final String dlMb =
            '${(receivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        final String totMb =
            '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

        final speedMb = currentSpeedBytesPerSec / (1024 * 1024);
        String speedStr = speedMb >= 0.05
            ? '${speedMb.toStringAsFixed(1)} MB/s'
            : 'Downloading...';

        if (receivedBytes >= totalBytes) {
          speedStr = 'Finalizing package...';
        }

        final remainingBytes = totalBytes - receivedBytes;
        String eta = '';
        if (currentSpeedBytesPerSec > 40 * 1024 && remainingBytes > 0) {
          final remainingSec =
              (remainingBytes / currentSpeedBytesPerSec).round();
          if (remainingSec > 60) {
            eta = '~${(remainingSec / 60).ceil()}m remaining';
          } else {
            eta = '~${remainingSec}s remaining';
          }
        }

        if (mounted) {
          setState(() {
            _progress = prog;
            _downloadedSize = dlMb;
            _totalSize = totMb;
            _speedText = speedStr;
            _etaText = eta;
          });
        }
      }

      await sink.flush();
      await sink.close();

      if (!await saveFile.exists()) {
        throw Exception('Download failed: file not written to storage.');
      }
      final diskSize = await saveFile.length();
      if (diskSize < 5 * 1024 * 1024) {
        throw Exception(
            'Downloaded package is incomplete (${(diskSize / (1024 * 1024)).toStringAsFixed(1)} MB). Please retry.');
      }

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
        _isComplete = true;
        _progress = 1.0;
        _speedText = '';
        _etaText = '';
        _downloadedFilePath = saveFile.path;
      });

      // Automatically launch the native package installer
      await _launchInstaller(saveFile.path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      client.close();
      _activeClient = null;
    }
  }

  void _cancelDownload() {
    _otaSubscription?.cancel();
    _otaSubscription = null;
    try {
      OtaUpdate().cancel();
    } catch (_) {}
    _activeClient?.close();
    _activeClient = null;
    setState(() {
      _isDownloading = false;
      _downloadError = 'Download cancelled';
    });
  }

  Future<void> _launchInstaller(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists() || await file.length() < 1024 * 1024) {
        if (mounted) {
          setState(() {
            _installError = 'Downloaded update file was not found. Please tap to re-download.';
            _isComplete = false;
          });
        }
        return;
      }

      if (Platform.isAndroid) {
        final result = await OpenFilex.open(
          filePath,
          type: 'application/vnd.android.package-archive',
        );
        debugPrint('Package installer result: ${result.type} - ${result.message}');
        if (result.type == ResultType.permissionDenied && mounted) {
          setState(() {
            _installError =
                'Permission Needed: Please allow "Install unknown apps" for Intelligent ERP in Android Settings, then tap Update Now.';
          });
        } else if (result.type == ResultType.error && mounted) {
          setState(() {
            _installError =
                'Could not launch updater: ${result.message}. Tap Update Now to retry.';
          });
        } else if (result.type == ResultType.done && mounted) {
          setState(() {
            _installError = null;
          });
        }
      } else {
        await OpenFilex.open(filePath);
      }
    } catch (e) {
      debugPrint('Error triggering package installer: $e');
      if (mounted) {
        setState(() {
          _installError = 'Could not start installation: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.info.isMandatory && !_isDownloading,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: AnimatedRays(
          borderRadius: BorderRadius.circular(22),
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildContent(),
                const SizedBox(height: 20),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String titleText;
    String subtitleText;

    if (_isComplete) {
      titleText = 'Ready to Install';
      subtitleText = widget.info.isMandatory
          ? 'Version ${widget.info.latestVersion}  •  Required Update'
          : 'Version ${widget.info.latestVersion}  •  Package Verified';
    } else if (_isDownloading) {
      titleText = 'Downloading Update';
      subtitleText = 'Intelligent ERP v${widget.info.latestVersion}';
    } else {
      titleText = widget.info.isMandatory ? 'Update Required' : 'Update Available';
      subtitleText = widget.info.isMandatory
          ? 'Version ${widget.info.latestVersion}  •  Required Update'
          : 'Version ${widget.info.latestVersion}  •  ${widget.info.fileSize}';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title & clean version subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitleText,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Close button if allowed (hidden for mandatory updates or while downloading)
        if (!widget.info.isMandatory && !_isDownloading)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isDownloading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Downloading update package directly in the app...',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Clean progress bar with rounded ends and neon gradient
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFF1E293B),
                  ),
                  FractionallySizedBox(
                    widthFactor: _progress > 0 ? _progress : 0.05,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF60A5FA),
                            Color(0xFF5EEAD4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(_progress * 100).toInt()}% • $_downloadedSize / $_totalSize',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Keep Intelligent ERP open while the package downloads.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11.5,
            ),
          ),
        ],
      );
    }

    if (_isComplete) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF34D399), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Update Ready to Install',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'The update package ($_totalSize) has been downloaded and verified. Tap Update Now to complete installation.',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (_installError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFFBBF24), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _installError!,
                      style: const TextStyle(
                        color: Color(0xFFFDE68A),
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    // Idle / Update Available Content
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.info.releaseNotes.isNotEmpty) ...[
          const Text(
            'WHAT\'S IN THIS UPDATE',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 235),
              child: Scrollbar(
                thumbVisibility: widget.info.releaseNotes.length > 4,
                radius: const Radius.circular(4),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.info.releaseNotes.map((note) {
                      final int colonIdx = note.indexOf(': ');
                      final bool hasColon = colonIdx != -1;
                      final String title = hasColon ? note.substring(0, colonIdx + 1) : '';
                      final String desc = hasColon ? note.substring(colonIdx + 2) : note;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF60A5FA),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: hasColon
                                  ? RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          height: 1.38,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '$title ',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                            text: desc,
                                            style: const TextStyle(
                                              color: Color(0xFFCBD5E1),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      note,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        height: 1.38,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (_downloadError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.red.shade400.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Download failed: $_downloadError',
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    if (_isDownloading) {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton(
          onPressed: _cancelDownload,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF94A3B8),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Cancel Download',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      );
    }

    if (_isComplete) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_downloadedFilePath != null) {
                  _launchInstaller(_downloadedFilePath!);
                } else {
                  _startInAppDownload();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.system_update_alt_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Update Now',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.info.isMandatory) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Update Later',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          ],
        ],
      );
    }

    // IDLE / NOT STARTED:
    // Electric Royal Blue button with download arrow & discrete Later button
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _startInAppDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_downward_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  _downloadError != null ? 'Retry Download' : 'Update Now',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        if (!widget.info.isMandatory) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Later',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

