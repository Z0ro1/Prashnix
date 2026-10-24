import 'package:flutter/material.dart';

/// Reusable avatar widget for leaderboard and user profile.
/// Resolves avatar filename to valid assets with fallback.
class UserAvatar extends StatelessWidget {
  final String? avatarId;
  final String username;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  const UserAvatar({
    super.key,
    required this.avatarId,
    this.username = '',
    this.size = 46,
    this.borderColor,
    this.borderWidth = 2,
  });

  static const List<String> availableAvatars = [
    'Nami.jpg',
    'brook.jpg',
    'chopper.jpg',
    'frenky.jpg',
    'luffy.jpg',
    'robin.jpg',
    'sanji.jpg',
    'ussop.jpg',
    'zoro.jpg',
  ];

  static String resolveAvatarPath(String? rawId) {
    if (rawId == null || rawId.trim().isEmpty) {
      return 'assets/avatars/luffy.jpg';
    }

    final trimmed = rawId.trim();

    // Already a full asset path
    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }

    // Direct match or case-insensitive match
    for (final file in availableAvatars) {
      if (file.toLowerCase() == trimmed.toLowerCase() ||
          file.toLowerCase().startsWith(trimmed.toLowerCase())) {
        return 'assets/avatars/$file';
      }
    }

    // Legacy avatar mappings
    final lower = trimmed.toLowerCase();
    if (lower.contains('1')) return 'assets/avatars/luffy.jpg';
    if (lower.contains('2')) return 'assets/avatars/zoro.jpg';
    if (lower.contains('3')) return 'assets/avatars/sanji.jpg';
    if (lower.contains('4')) return 'assets/avatars/Nami.jpg';
    if (lower.contains('5')) return 'assets/avatars/chopper.jpg';
    if (lower.contains('6')) return 'assets/avatars/robin.jpg';
    if (lower.contains('7')) return 'assets/avatars/ussop.jpg';
    if (lower.contains('8')) return 'assets/avatars/brook.jpg';

    return 'assets/avatars/luffy.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = resolveAvatarPath(avatarId);
    final initial = username.trim().isNotEmpty ? username.trim()[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        boxShadow: borderColor != null
            ? [
                BoxShadow(
                  color: borderColor!.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF283B46),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.45,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
