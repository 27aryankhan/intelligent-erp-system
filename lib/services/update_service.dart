import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
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
      isCritical ||
      (UpdateService.effectiveVersionCode < minSupportedVersionCode);

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

  /// Current running version of the app (matches pubspec.yaml version 1.0.8+9)
  static const String currentVersion = '1.0.8';
  static const int currentVersionCode = 9;
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
      barrierDismissible: true,
      builder: (ctx) => _InAppUpdateDialog(info: info),
    );
  }
}

/// Animated Rays Aurora background inspired by VengeanceUI / shadcn AnimatedRays
/// Colors: Sky Blue (#60a5fa), Fuchsia/Magenta (#e879f9), Teal (#5eead4), Indigo (#818cf8)
class AnimatedRays extends StatefulWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final Border? border;
  final BoxShadow? glowShadow;
  final EdgeInsetsGeometry? padding;

  const AnimatedRays({
    super.key,
    required this.child,
    this.borderRadius,
    this.border,
    this.glowShadow,
    this.padding,
  });

  @override
  State<AnimatedRays> createState() => _AnimatedRaysState();
}

class _AnimatedRaysState extends State<AnimatedRays>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(24);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: widget.glowShadow != null
            ? [widget.glowShadow!]
            : [
                BoxShadow(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.16),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFFE879F9).withValues(alpha: 0.12),
                  blurRadius: 38,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Animated Aurora Rays Canvas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      painter: _AnimatedRaysPainter(
                        animationValue: _controller.value,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Frosted glassmorphism overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: widget.border ??
                        Border.all(
                          color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.07),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Foreground Content
            Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedRaysPainter extends CustomPainter {
  final double animationValue;

  _AnimatedRaysPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Deep cosmic obsidian base (replaces dull flat dark blue)
    final basePaint = Paint()..color = const Color(0xFF080D1A);
    canvas.drawRect(rect, basePaint);

    // 2. Animated Aurora Light Waves (VengeanceUI palette)
    final double t = animationValue * 2 * math.pi;

    // Orb 1: Sky Blue (#60A5FA)
    final orb1Paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.65 + math.sin(t) * 0.25, -0.65 + math.cos(t) * 0.2),
        radius: 1.15,
        colors: [
          const Color(0xFF60A5FA).withValues(alpha: 0.38),
          const Color(0xFF60A5FA).withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, orb1Paint);

    // Orb 2: Fuchsia/Magenta (#E879F9)
    final orb2Paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.6 + math.cos(t * 0.8) * 0.25, 0.45 + math.sin(t * 0.8) * 0.2),
        radius: 0.95,
        colors: [
          const Color(0xFFE879F9).withValues(alpha: 0.30),
          const Color(0xFFE879F9).withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, orb2Paint);

    // Orb 3: Turquoise/Teal (#5EEAD4)
    final orb3Paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.2 + math.sin(t * 1.2) * 0.35, 0.15 + math.cos(t * 1.2) * 0.25),
        radius: 0.85,
        colors: [
          const Color(0xFF5EEAD4).withValues(alpha: 0.26),
          const Color(0xFF5EEAD4).withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, orb3Paint);

    // 3. Angled Ray Stripes (100° repeating linear beams from VengeanceUI)
    canvas.save();
    canvas.clipRect(rect);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(10 * math.pi / 180);
    canvas.translate(-size.width / 2, -size.height / 2);

    final stripePaint = Paint()..style = PaintingStyle.fill;
    final double stripeSpacing = 28.0;
    final double stripeWidth = 6.5;
    final double waveOffset = (animationValue * stripeSpacing * 2) % stripeSpacing;

    final double totalW = size.width * 1.6;
    final double totalH = size.height * 1.6;

    for (double x = -totalW * 0.3 + waveOffset; x < totalW; x += stripeSpacing) {
      final normX = (x / totalW).clamp(0.0, 1.0);
      Color stripeColor;
      if (normX < 0.33) {
        stripeColor = Color.lerp(
            const Color(0xFF60A5FA), const Color(0xFFE879F9), normX / 0.33)!;
      } else if (normX < 0.66) {
        stripeColor = Color.lerp(
            const Color(0xFFE879F9), const Color(0xFF5EEAD4), (normX - 0.33) / 0.33)!;
      } else {
        stripeColor = Color.lerp(
            const Color(0xFF5EEAD4), const Color(0xFF60A5FA), (normX - 0.66) / 0.34)!;
      }

      stripePaint.color = stripeColor.withValues(
          alpha: 0.06 + 0.04 * math.sin(t + normX * 6));
      canvas.drawRect(
          Rect.fromLTWH(x, -totalH * 0.3, stripeWidth, totalH), stripePaint);
    }
    canvas.restore();

    // 4. Subtle Radial Vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.0),
        radius: 1.25,
        colors: [
          Colors.transparent,
          const Color(0xFF030712).withValues(alpha: 0.6),
        ],
        stops: const [0.35, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedRaysPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
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
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: AnimatedRays(
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildContent(),
                const SizedBox(height: 18),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Color badgeColor;
    IconData headerIcon;
    String titleText;
    String badgeText;

    if (_isComplete) {
      badgeColor = const Color(0xFF10B981);
      headerIcon = Icons.verified_rounded;
      titleText = 'Ready to Install';
      badgeText = 'Verified ($_totalSize)';
    } else if (_isDownloading) {
      badgeColor = const Color(0xFF60A5FA);
      headerIcon = Icons.downloading_rounded;
      titleText = 'Downloading Update';
      badgeText = 'Intelligent ERP v${widget.info.latestVersion}';
    } else {
      badgeColor = const Color(0xFF60A5FA);
      headerIcon = Icons.auto_awesome_rounded;
      titleText = 'Update Available';
      badgeText = 'v${UpdateService.currentVersion} ➔ v${widget.info.latestVersion}';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Glowing Aurora Icon Container
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF60A5FA),
                Color(0xFFE879F9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            headerIcon,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        // Title & Version Badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!_isComplete && !_isDownloading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5EEAD4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF5EEAD4).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _totalSize,
                        style: const TextStyle(
                          color: Color(0xFF5EEAD4),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Close button if allowed
        if (!_isDownloading)
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            color: Colors.white60,
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          // Custom glowing aurora progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
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
                            Color(0xFFE879F9),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_progress * 100).toInt()}% • $_downloadedSize / $_totalSize',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (_speedText.isNotEmpty)
                Text(
                  _speedText,
                  style: const TextStyle(
                    color: Color(0xFF5EEAD4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Please keep the app open while the package downloads.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
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
              color: const Color(0xFF10B981).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified, color: Color(0xFF34D399), size: 24),
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
          const SizedBox(height: 12),
          const Text(
            'If the installation screen didn\'t pop up, tap "Install Update" below.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.info.releaseNotes.isNotEmpty) ...[
          const Text(
            'WHAT\'S NEW',
            style: TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.info.releaseNotes.map((note) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 11,
                              color: Color(0xFF5EEAD4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
            ),
          ),
        ],
        if (_downloadError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.red.shade400.withValues(alpha: 0.4),
              ),
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
        height: 42,
        child: OutlinedButton(
          onPressed: _cancelDownload,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            side: BorderSide(
              color: const Color(0xFFEF4444).withValues(alpha: 0.5),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Cancel Download',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    if (_isComplete) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF059669),
                    Color(0xFF10B981),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_downloadedFilePath != null) {
                    _launchInstaller(_downloadedFilePath!);
                  }
                },
                icon: const Icon(Icons.install_mobile_rounded, size: 18),
                label: const Text(
                  'Install Update',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
        ],
      );
    }

    // IDLE / NOT STARTED:
    // Glowing gradient button, NO "Later" button!
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0284C7),
              Color(0xFF6366F1),
              Color(0xFF9333EA),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _startInAppDownload,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text(
            _downloadError != null ? 'Retry Download' : 'Update Now',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
