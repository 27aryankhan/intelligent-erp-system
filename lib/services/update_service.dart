import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

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
  bool get isMandatory =>
      isCritical || (UpdateService.effectiveVersionCode < minSupportedVersionCode);

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

  /// Current running version of the app (matches pubspec.yaml version 1.0.7+8)
  static const String currentVersion = '1.0.7';
  static const int currentVersionCode = 8;
  static int _cachedEffectiveVersionCode = currentVersionCode;

  static int get effectiveVersionCode => _cachedEffectiveVersionCode;

  static Future<void> syncStoredVersionCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored =
          prefs.getInt('installed_update_code') ?? currentVersionCode;
      if (stored > _cachedEffectiveVersionCode) {
        _cachedEffectiveVersionCode = stored;
      }
    } catch (_) {}
  }

  /// Primary 100% Free CDN URL on GitHub
  static const String primaryUpdateUrl =
      'https://raw.githubusercontent.com/27aryankhan/intelligent-erp-system/main/version.json';

  bool _hasPromptedThisSession = false;

  /// Check whether an update is available on the remote server
  Future<AppUpdateInfo?> checkForUpdate() async {
    await syncStoredVersionCode();
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
          content: Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.greenAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your app is updated till date and the app you are using is updated. (v$currentVersion)',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
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
      barrierDismissible: true,
      builder: (ctx) => _InAppUpdateDialog(info: info),
    );
  }
}

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
  double _progress = 0.0;
  String _downloadedSize = '0.0 MB';
  String _totalSize = '21.0 MB';
  String _speedText = '';
  String _etaText = '';
  String? _downloadedFilePath;
  http.Client? _activeClient;

  @override
  void initState() {
    super.initState();
    _totalSize = widget.info.fileSize;
  }

  @override
  void dispose() {
    _activeClient?.close();
    super.dispose();
  }

  Future<void> _startInAppDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadError = null;
      _progress = 0.0;
      _downloadedSize = '0.0 MB';
      _speedText = 'Connecting...';
      _etaText = 'Calculating time...';
    });

    final client = http.Client();
    _activeClient = client;

    try {
      String targetUrl =
          UpdateService.resolveDirectDownloadUrl(widget.info.downloadUrl);
      http.StreamedResponse? streamedResponse;
      int redirectHops = 0;

      // Robustly follow redirects across CDNs (GitHub ➔ Release ➔ S3/Azure asset blob)
      while (redirectHops < 8) {
        final request = http.Request('GET', Uri.parse(targetUrl));
        request.followRedirects = true;
        request.maxRedirects = 8;

        final res = await client.send(request);
        if (res.statusCode >= 300 &&
            res.statusCode < 400 &&
            res.headers.containsKey('location')) {
          targetUrl = res.headers['location']!;
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
          : (21 * 1024 * 1024);

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

      // 15 second chunk timeout to eliminate any socket hang or 10-minute freeze
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
        // Sample speed every 350ms for stable metrics
        if (elapsedMs - lastSampleTimeMs >= 350) {
          final timeDeltaSec = (elapsedMs - lastSampleTimeMs) / 1000.0;
          final bytesDelta = receivedBytes - lastSampleBytes;
          currentSpeedBytesPerSec = bytesDelta / timeDeltaSec;

          lastSampleBytes = receivedBytes;
          lastSampleTimeMs = elapsedMs;
        }

        // Cap at 0.95 during active chunk stream to prevent freezing at 100%
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
        } else if (prog > 0.05) {
          eta = 'Finalizing...';
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

      // Update cached and stored version code so user won't get prompted again
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('installed_update_code', widget.info.latestVersionCode);
        UpdateService._cachedEffectiveVersionCode = widget.info.latestVersionCode;
      } catch (_) {}

      setState(() {
        _isDownloading = false;
        _isComplete = true;
        _progress = 1.0;
        _speedText = '';
        _etaText = '';
        _downloadedFilePath = saveFile.path;
      });

      // Automatically launch the native package installer on Android inside the phone
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
    _activeClient?.close();
    _activeClient = null;
    setState(() {
      _isDownloading = false;
      _downloadError = 'Download cancelled';
    });
  }

  Future<void> _launchInstaller(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final result = await OpenFilex.open(
          filePath,
          type: 'application/vnd.android.package-archive',
        );
        debugPrint('Package installer result: ${result.type} - ${result.message}');
        if (result.type == ResultType.permissionDenied && mounted) {
          setState(() {
            _downloadError =
                'Permission needed: Please enable "Install unknown apps" for Intelligent ERP in Android Settings, then tap Install.';
          });
        }
      } else {
        await OpenFilex.open(filePath);
      }
    } catch (e) {
      debugPrint('Error triggering package installer: $e');
      if (mounted) {
        setState(() {
          _downloadError = 'Failed to open installer: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDownloading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF0F172A),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: _buildTitle(),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _buildContent(),
        ),
        actions: _buildActions(),
      ),
    );
  }

  Widget _buildTitle() {
    Color subtitleColor;
    String titleText;
    String subtitleText;

    if (_isComplete) {
      subtitleColor = const Color(0xFF10B981);
      titleText = 'Ready to Install';
      subtitleText = 'Update Package Verified ($_totalSize)';
    } else if (_isDownloading) {
      subtitleColor = const Color(0xFF38BDF8);
      titleText = 'Downloading Update';
      subtitleText = 'Intelligent ERP v${widget.info.latestVersion}';
    } else {
      subtitleColor = const Color(0xFF38BDF8);
      titleText = 'Update Available';
      subtitleText =
          'v${UpdateService.currentVersion} ➔ v${widget.info.latestVersion}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitleText,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
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
            'Downloading update package directly inside your app...',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              minHeight: 12,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_progress * 100).toInt()}% • $_downloadedSize / $_totalSize',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              if (_speedText.isNotEmpty)
                Text(
                  _speedText,
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          if (_etaText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.timer_outlined,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  _etaText,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Please keep the app open while the package downloads.',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified, color: Color(0xFF10B981), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your app is updated till date!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Package downloaded successfully ($_totalSize). The Android system installer has opened to finalize the update.',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'If the installation screen didn\'t pop up, tap "Install Update" below.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'A new update is ready for install:',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _totalSize,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.info.releaseNotes.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.info.releaseNotes.map((note) {
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
        if (_downloadError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Download failed: $_downloadError',
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (widget.info.isMandatory) ...[
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
    );
  }

  List<Widget> _buildActions() {
    if (_isDownloading) {
      return [
        TextButton(
          onPressed: _cancelDownload,
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFFEF4444)),
          ),
        ),
      ];
    }

    if (_isComplete) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_downloadedFilePath != null) {
              _launchInstaller(_downloadedFilePath!);
            }
          },
          icon: const Icon(Icons.install_mobile_rounded, size: 18),
          label: const Text('Install Update'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
        ),
      ];
    }

    // IDLE / NOT STARTED:
    // IMPORTANT: "Later" option removed as requested by user
    return [
      ElevatedButton.icon(
        onPressed: _startInAppDownload,
        icon: const Icon(Icons.download_rounded, size: 18),
        label: Text(_downloadError != null ? 'Retry Download' : 'Update Now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    ];
  }
}
