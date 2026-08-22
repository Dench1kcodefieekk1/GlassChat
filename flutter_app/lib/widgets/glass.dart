import 'dart:ui';

import 'package:flutter/material.dart';

/// Glassmorphism container: blur backdrop + translucent gradient fill +
/// subtle rounded stroke — the GlassChat signature card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blur;
  final Color color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.blur = 14,
    this.color = const Color(0x14FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Small gradient token badge (TYP0K "T", USDT "₮").
class TokenIcon extends StatelessWidget {
  final String text;
  final List<Color> colors;
  final double size;

  const TokenIcon({
    super.key,
    required this.text,
    required this.colors,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

/// Persistent launcher pill shown above the composer in system bot chats.
class MiniAppPill extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const MiniAppPill({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      color: const Color(0x22FFFFFF),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
