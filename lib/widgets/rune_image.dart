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
    Widget image;
    if (imageUrl.isNotEmpty) {
      image = Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _assetOrFallback(fallback),
      );
    } else {
      image = _assetOrFallback(fallback);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: size, height: size, child: image),
    );
  }

  Widget _assetOrFallback(Widget fallback) {
    if (assetPath.isEmpty) return fallback;
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
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
