import 'package:flutter/material.dart';

class RuneImage extends StatelessWidget {
  final String imageUrl;
  final String assetPath;
  final String fallbackText;
  final double size;
  final double borderRadius;
  final double fallbackFontSize;

  const RuneImage({
    super.key,
    this.imageUrl = '',
    this.assetPath = '',
    required this.fallbackText,
    required this.size,
    required this.borderRadius,
    double? fallbackFontSize,
  }) : fallbackFontSize = fallbackFontSize ?? size * 0.38;

  @override
  Widget build(BuildContext context) {
    final fallback = _fallback();
    final resolvedAssetPath = _resolveAssetPath(assetPath, imageUrl);
    final resolvedImageUrl = imageUrl.startsWith(RegExp(r'https?://'))
        ? imageUrl
        : '';
    final image = resolvedAssetPath.isNotEmpty
        ? _assetOrNetworkOrFallback(
            fallback,
            resolvedAssetPath,
            resolvedImageUrl,
          )
        : _networkOrFallback(fallback, resolvedImageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: size, height: size, child: image),
    );
  }

  Widget _assetOrNetworkOrFallback(
    Widget fallback,
    String resolvedAssetPath,
    String resolvedImageUrl,
  ) {
    return Image.asset(
      resolvedAssetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _networkOrFallback(fallback, resolvedImageUrl),
    );
  }

  Widget _networkOrFallback(Widget fallback, String resolvedImageUrl) {
    if (resolvedImageUrl.isEmpty) return fallback;
    return Image.network(
      resolvedImageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  String _resolveAssetPath(String explicitPath, String rawImage) {
    if (explicitPath.isNotEmpty) return explicitPath;
    final lower = rawImage.toLowerCase();
    final fwMatch = RegExp(r'fw[_\\/-]?(\d+)').firstMatch(lower);
    if (fwMatch != null) {
      return 'assets/runes/fw/fw_${fwMatch.group(1)}.png';
    }
    final dotamdMatch = RegExp(r'dotamd[_\\/-]?(\d+)').firstMatch(lower);
    if (dotamdMatch != null) {
      return 'assets/runes/ui/fw.png';
    }
    if (lower.contains('rune')) {
      return 'assets/runes/ui/fw.png';
    }
    return '';
  }

  Widget _fallback() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFF3D444D),
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: Center(
      child: Text(
        fallbackText.isNotEmpty ? fallbackText[0] : '?',
        style: TextStyle(
          color: const Color(0xFFCDD9E5),
          fontSize: fallbackFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
