import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/hitam_auth_service.dart';

/// Universal, robust widget to display student profile pictures
/// Handles:
/// 1. Network URLs (with authenticated WebPros session cookies and headers)
/// 2. Base64 / data URIs (data:image/jpeg;base64,...)
/// 3. Memory bytes
/// 4. Graceful high-contrast initials or icon fallback
/// 5. Fullscreen zoom dialog on tap
class StudentPhotoWidget extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final String? rollNo;
  final double size;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final BoxFit fit;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final bool enableZoom;
  final VoidCallback? onTap;

  const StudentPhotoWidget({
    super.key,
    required this.photoUrl,
    this.name = '',
    this.rollNo,
    this.size = 50,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.fit = BoxFit.cover,
    this.backgroundColor,
    this.fallbackIcon = Icons.school_rounded,
    this.enableZoom = false,
    this.onTap,
  });

  static bool _isBlacklisted(String? url, [Uint8List? bytes]) {
    if (url == null || url.trim().isEmpty) return true;
    final trimmed = url.trim();
    final lower = trimmed.toLowerCase();

    if (lower.contains('title_head') ||
        lower.contains('collegeimages') ||
        lower.contains('collegeimage') ||
        lower.contains('title_') ||
        lower.contains('head.jpg') ||
        lower.contains('head.png') ||
        lower.contains('head.gif') ||
        lower.contains('banner') ||
        lower.contains('logo') ||
        lower.contains('header') ||
        lower.contains('footer') ||
        lower.contains('spacer') ||
        lower.contains('dot.gif')) {
      return true;
    }

    if (bytes != null) {
      if (bytes.length == 52868 || bytes.length < 500) {
        return true;
      }
    }

    if (lower.startsWith('data:image') ||
        lower.startsWith('data:application') ||
        lower.startsWith('/9j/')) {
      if (trimmed.contains('7AARRHVja3k')) {
        return true;
      }
      try {
        final clean = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
        final sanitized = clean.replaceAll(RegExp(r'\s+'), '');
        final approxLen = (sanitized.length * 3) ~/ 4;
        if (approxLen >= 52800 && approxLen <= 52950) {
          final decoded = base64Decode(sanitized);
          if (decoded.length == 52868 || decoded.length < 500) {
            return true;
          }
        } else if (approxLen < 400) {
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  bool get _isBase64 {
    if (photoUrl == null || photoUrl!.trim().isEmpty) return false;
    final trimmed = photoUrl!.trim();
    if (_isBlacklisted(trimmed)) return false;
    return trimmed.startsWith('data:image') ||
        trimmed.startsWith('data:application') ||
        trimmed.startsWith('/9j/') ||
        trimmed.startsWith('iVBORw0KGgo');
  }

  Uint8List? _decodeBase64(String raw) {
    if (_isBlacklisted(raw)) return null;
    try {
      final clean = raw.contains(',') ? raw.split(',').last : raw;
      final sanitized = clean.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64Decode(sanitized);
      if (_isBlacklisted(raw, bytes)) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Widget _buildFallback() {
    final displayName = name.trim();
    final letter = displayName.isNotEmpty ? displayName[0].toUpperCase() : '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF1E293B),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? (borderRadius ?? BorderRadius.circular(8)) : null,
      ),
      alignment: Alignment.center,
      child: letter.isNotEmpty
          ? Text(
              letter,
              style: TextStyle(
                color: const Color(0xFF38BDF8),
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            )
          : Icon(
              fallbackIcon,
              color: const Color(0xFF38BDF8),
              size: size * 0.5,
            ),
    );
  }

  Widget _buildImageContent() {
    final rawUrl = photoUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty || _isBlacklisted(rawUrl)) {
      return _buildFallback();
    }

    // 1. Base64 / Data URI image
    if (_isBase64) {
      final bytes = _decodeBase64(rawUrl);
      if (bytes != null && bytes.isNotEmpty && !_isBlacklisted(rawUrl, bytes)) {
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      }
      return _buildFallback();
    }

    // 2. HTTP / HTTPS Network image with authenticated session cookies
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      final auth = HitamAuthService();
      final Map<String, String>? headers = auth.sessionCookies.isNotEmpty
          ? {
              'Cookie': auth.cookieHeader,
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Referer': 'https://www.webprosindia.com/hitam/StudentMaster.aspx',
            }
          : null;

      return Image.network(
        rawUrl,
        width: size,
        height: size,
        fit: fit,
        headers: headers,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: backgroundColor ?? const Color(0xFF0F172A),
            child: Center(
              child: SizedBox(
                width: size * 0.35,
                height: size * 0.35,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF38BDF8),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    // Unrecognized format fallback
    return _buildFallback();
  }

  void _showZoomDialog(BuildContext context) {
    if (_isBlacklisted(photoUrl)) return;
    showStudentPhotoPreviewDialog(
      context,
      photoUrl: photoUrl,
      name: name,
      rollNo: rollNo,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF0F172A),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? (borderRadius ?? BorderRadius.circular(8)) : null,
        border: border,
        boxShadow: boxShadow,
      ),
      child: shape == BoxShape.circle
          ? ClipOval(child: _buildImageContent())
          : ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              child: _buildImageContent(),
            ),
    );

    if (enableZoom || onTap != null) {
      return GestureDetector(
        onTap: onTap ?? (enableZoom ? () => _showZoomDialog(context) : null),
        child: content,
      );
    }

    return content;
  }
}

/// Helper to display a large high-resolution profile picture preview dialog
void showStudentPhotoPreviewDialog(
  BuildContext context, {
  required String? photoUrl,
  String name = '',
  String? rollNo,
}) {
  if (photoUrl == null || photoUrl.trim().isEmpty) return;
  final rawUrl = photoUrl.trim();
  if (StudentPhotoWidget._isBlacklisted(rawUrl)) return;

  final bool isBase64 = rawUrl.startsWith('data:image') ||
      rawUrl.startsWith('data:application') ||
      rawUrl.startsWith('/9j/') ||
      rawUrl.startsWith('iVBORw0KGgo');

  Uint8List? bytes;
  if (isBase64) {
    try {
      final clean = rawUrl.contains(',') ? rawUrl.split(',').last : rawUrl;
      bytes = base64Decode(clean.replaceAll(RegExp(r'\s+'), ''));
      if (StudentPhotoWidget._isBlacklisted(rawUrl, bytes)) {
        return;
      }
    } catch (_) {}
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340, maxWidth: 320),
                child: bytes != null
                    ? Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(
                          height: 200,
                          child: Center(
                            child: Icon(Icons.broken_image_rounded,
                                color: Colors.white70, size: 48),
                          ),
                        ),
                      )
                    : Image.network(
                        rawUrl,
                        fit: BoxFit.contain,
                        headers: HitamAuthService().sessionCookies.isNotEmpty
                            ? {
                                'Cookie': HitamAuthService().cookieHeader,
                                'User-Agent':
                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                                'Referer': 'https://www.webprosindia.com/hitam/StudentMaster.aspx',
                              }
                            : null,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(
                          height: 200,
                          child: Center(
                            child: Icon(Icons.broken_image_rounded,
                                color: Colors.white70, size: 48),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (name.isNotEmpty || (rollNo != null && rollNo.isNotEmpty)) ...[
            const SizedBox(height: 14),
            if (name.isNotEmpty)
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (rollNo != null && rollNo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                rollNo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    ),
  );
}
