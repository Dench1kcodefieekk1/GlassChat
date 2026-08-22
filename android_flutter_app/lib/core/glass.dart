import 'dart:ui';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Glassmorphism card: blur backdrop, translucent fill, hairline stroke.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.blur = 14,
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
            color: Colors.white.withOpacity(0.06),
            borderRadius: borderRadius,
            border: Border.all(color: AppTheme.separator),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Avatar with initials and an online status indicator dot.
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool isOnline;
  final bool isVerified;

  const UserAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.isOnline = false,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((part) => part.isNotEmpty ? part[0] : '').take(2).join();
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5A7BEF), Color(0xFF8C55D6)],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: size * 0.38,
            ),
          ),
        ),
        if (isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                color: AppTheme.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded,
                  size: 15, color: AppTheme.accent),
            ),
          )
        else if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppTheme.online,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.background, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// Unread count pill.
class UnreadBadge extends StatelessWidget {
  final int count;

  const UnreadBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
