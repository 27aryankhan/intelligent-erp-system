import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
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

  /// Current running version of the app (matches pubspec.yaml version 1.3.0+19)
  static const String currentVersion = '1.3.0';
  static const int currentVersionCode = 19;

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

  /// Displays the modern in-app update notification dialog with Animated Rays & Clear iOS Glassmorphism
  void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.70),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim1, anim2) {
        return PopScope(
          canPop: !info.isMandatory,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Vengeance UI Animated Rays flowing across the full background
              const Positioned.fill(
                child: AnimatedRays(
                  borderRadius: BorderRadius.zero,
                  backgroundColor: Color(0xFF04060A),
                  opacity: 0.85,
                  speedSeconds: 22.0,
                  isDark: true,
                ),
              ),

              // 2. Translucent cyber vignette to create cinematic focus on the central modal
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.20,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Centered Clear iOS Glassmorphism Update Dialog
              Center(
                child: _InAppUpdateDialog(info: info),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  /// Displays the update dialog in preview mode for UI & UX testing
  void showTestPreviewDialog(BuildContext context) {
    final previewInfo = AppUpdateInfo(
      latestVersion: '1.2.6',
      latestVersionCode: 19,
      minSupportedVersionCode: 11,
      downloadUrl:
          'https://github.com/27aryankhan/intelligent-erp-system/releases/latest/download/Intelligent.ERP.apk',
      fileSize: '38.8 MB',
      releaseNotes: const [
        'Animated Rays Visuals: Cosmic flowing light rays with authentic Vengeance UI difference blend',
        'Clear iOS Glassmorphism: Ultra-clarity frosted glass card with 28px corners & specular borders',
        'Touch Protection: Eliminated accidental barrier touch dismissals to ensure deliberate cancellation',
      ],
      isCritical: false,
    );
    showUpdateDialog(context, previewInfo);
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
  bool _isUserCancelled = false;
  String? _downloadError;
  String? _installError;
  double _progress = 0.0;
  String _downloadedSize = '0.0 MB';
  String _totalSize = '38.8 MB';
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
      return double.tryParse(match.group(1) ?? '38.8') ?? 38.8;
    }
    return 38.8;
  }

  /// Sanitizes raw network exception strings into clean, human-friendly messages
  String _sanitizeErrorMessage(dynamic error) {
    final raw = error.toString().replaceAll('Exception: ', '').trim();
    if (raw.isEmpty) {
      return 'Download interrupted. Tap Retry to try again.';
    }
    final lower = raw.toLowerCase();
    if (lower.contains('clientconnection closed') ||
        lower.contains('connection closed') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection reset') ||
        lower.contains('broken pipe') ||
        lower.contains('clientexception')) {
      return 'Connection interrupted. Check your internet and tap Retry.';
    }
    if (lower.contains('timeoutexception') || lower.contains('timed out')) {
      return 'Download timed out. Check your connection and tap Retry.';
    }
    if (lower.contains('404') || lower.contains('403') || lower.contains('not found')) {
      return 'Update package is temporarily unavailable. Please try again later.';
    }
    if (lower.contains('space') || lower.contains('storage') || lower.contains('disk')) {
      return 'Insufficient storage on your device. Free up space and tap Retry.';
    }
    // Clean any URLs or presigned query params
    if (raw.contains('http://') || raw.contains('https://') || raw.contains('uri=')) {
      return 'Network error occurred during download. Tap Retry to try again.';
    }
    if (raw.length > 80) {
      return '${raw.substring(0, 77)}...';
    }
    return raw;
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
    _isUserCancelled = true;
    _otaSubscription?.cancel();
    _activeClient?.close();
    super.dispose();
  }

  Future<void> _startInAppDownload() async {
    _isUserCancelled = false;
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
            if (!mounted || _isUserCancelled) return;
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
                if (_isUserCancelled) return;
                setState(() {
                  _isDownloading = false;
                  _downloadError = _sanitizeErrorMessage(
                      event.value ?? 'Download failed. Please tap retry.');
                });
                break;
              case OtaStatus.CANCELED:
                setState(() {
                  _isDownloading = false;
                  _downloadError = null;
                  _progress = 0.0;
                  _speedText = '';
                  _etaText = '';
                });
                break;
            }
          },
          onError: (e) {
            if (!mounted || _isUserCancelled) return;
            setState(() {
              _isDownloading = false;
              _downloadError = _sanitizeErrorMessage(e);
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
    IOSink? sink;

    try {
      http.StreamedResponse? streamedResponse;
      int redirectHops = 0;
      String currentUrl = targetUrl;

      // Robustly follow redirects across CDNs
      while (redirectHops < 8) {
        if (_isUserCancelled) return;
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

      if (_isUserCancelled) return;

      if (streamedResponse == null || streamedResponse.statusCode != 200) {
        throw Exception(
            'Server responded with HTTP ${streamedResponse?.statusCode ?? "error"}');
      }

      final int? reportedLength = streamedResponse.contentLength;
      final int totalBytes = (reportedLength != null && reportedLength > 0)
          ? reportedLength
          : (expectedMb * 1000 * 1000).round();

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

      if (_isUserCancelled) return;

      sink = saveFile.openWrite();
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
        if (!mounted || _isUserCancelled) break;
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
            '${(receivedBytes / (1000 * 1000)).toStringAsFixed(1)} MB';
        final String totMb =
            '${(totalBytes / (1000 * 1000)).toStringAsFixed(1)} MB';

        final speedMb = currentSpeedBytesPerSec / (1000 * 1000);
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

        if (mounted && !_isUserCancelled) {
          setState(() {
            _progress = prog;
            _downloadedSize = dlMb;
            _totalSize = totMb;
            _speedText = speedStr;
            _etaText = eta;
          });
        }
      }

      if (_isUserCancelled) {
        try {
          await sink.close();
        } catch (_) {}
        sink = null;
        try {
          if (await saveFile.exists()) {
            await saveFile.delete();
          }
        } catch (_) {}
        return;
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (!await saveFile.exists()) {
        throw Exception('Download failed: file not written to storage.');
      }
      final diskSize = await saveFile.length();
      if (diskSize < 5 * 1024 * 1024) {
        throw Exception(
            'Downloaded package is incomplete (${(diskSize / (1024 * 1024)).toStringAsFixed(1)} MB). Please retry.');
      }

      if (!mounted || _isUserCancelled) return;

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
      if (!mounted || _isUserCancelled) return;
      setState(() {
        _isDownloading = false;
        _downloadError = _sanitizeErrorMessage(e);
      });
    } finally {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      try {
        client.close();
      } catch (_) {}
      if (_activeClient == client) {
        _activeClient = null;
      }
    }
  }

  void _cancelDownload() {
    _isUserCancelled = true;
    _otaSubscription?.cancel();
    _otaSubscription = null;
    try {
      OtaUpdate().cancel();
    } catch (_) {}
    try {
      _activeClient?.close();
    } catch (_) {}
    _activeClient = null;
    if (mounted) {
      setState(() {
        _isDownloading = false;
        _downloadError = null;
        _progress = 0.0;
        _speedText = '';
        _etaText = '';
      });
    }
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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: GestureDetector(
        onTap: () {}, // Prevent taps inside dialog from closing it
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
                blurRadius: 28,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.22),
                blurRadius: 1,
                spreadRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      const Color(0xFF1E2438).withValues(alpha: 0.45),
                      const Color(0xFF080D1A).withValues(alpha: 0.65),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
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
      subtitleText = 'Version ${widget.info.latestVersion}';
    } else if (_isDownloading) {
      titleText = 'Downloading Update';
      subtitleText = 'Version ${widget.info.latestVersion}';
    } else {
      titleText = widget.info.isMandatory ? 'Update Required' : 'Update Available';
      subtitleText = 'Version ${widget.info.latestVersion}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          titleText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitleText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 13,
            fontWeight: FontWeight.w500,
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
          Text(
            'Downloading update package directly in the app...',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.80), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  if (_progress > 0)
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress.clamp(0.0, 1.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _progress >= 0.75
                                ? const [
                                    Color(0xFF34D399),
                                    Color(0xFF10B981),
                                  ]
                                : const [
                                    Color(0xFFFF5252),
                                    Color(0xFFE11D48),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              Text(
                '$_downloadedSize / $_totalSize',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Keep Intelligent ERP open while the package downloads.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
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
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                width: 1.0,
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
                  'The update package ($_totalSize) has been downloaded and verified. Tap Install Update to complete installation.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
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
                borderRadius: BorderRadius.circular(12),
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

    // Idle / Update Available Content: Display notes directly on glass without enclosing box
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.info.releaseNotes.isNotEmpty) ...[
          Text(
            'WHAT\'S IN THIS UPDATE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: Scrollbar(
              thumbVisibility: widget.info.releaseNotes.length > 3,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.info.releaseNotes.map((note) {
                    final int colonIdx = note.indexOf(': ');
                    final bool hasColon = colonIdx != -1;
                    final String title =
                        hasColon ? note.substring(0, colonIdx + 1) : '';
                    final String desc =
                        hasColon ? note.substring(colonIdx + 2) : note;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
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
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              note,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: 12.5,
                                height: 1.38,
                              ),
                            ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
        if (_downloadError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.shade400.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _downloadError!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.redAccent,
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

  Widget _buildActions() {
    if (_isDownloading) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _cancelDownload,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'Cancel Download',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    if (_isComplete) {
      return Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (_downloadedFilePath != null) {
                  _launchInstaller(_downloadedFilePath!);
                } else {
                  _startInAppDownload();
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.system_update_alt_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Install Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.info.isMandatory) ...[
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                      width: 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Later',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // IDLE / NOT STARTED:
    if (!widget.info.isMandatory) {
      return Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Later',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _startInAppDownload,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3B82F6),
                        Color(0xFF1D4ED8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _downloadError != null ? 'Retry' : 'Update Now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Mandatory Update: Full-width Update button
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _startInAppDownload,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B82F6),
                Color(0xFF1D4ED8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.38),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _downloadError != null ? 'Retry Download' : 'Update Now',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

