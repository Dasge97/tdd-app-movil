import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const _personaAssets = {
  'artemisa', 'a-23', 'axion', 'marcos', 'nodo', 'nyx', 'pixie', 'raul',
};

class Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final double size;
  final bool isAiPersona;

  const Avatar({
    super.key,
    required this.username,
    this.avatarUrl,
    this.size = 36,
    this.isAiPersona = false,
  });

  BorderRadius get _borderRadius => isAiPersona
      ? BorderRadius.circular(size * 0.18)
      : BorderRadius.circular(size / 2);

  String? get _personaAssetPath {
    if (!isAiPersona) return null;
    final key = username.toLowerCase();
    if (_personaAssets.contains(key)) {
      return 'assets/personas/$key.png';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _personaAssetPath;
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: _borderRadius,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: _borderRadius,
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => _fallback(),
          errorWidget: (_, _, _) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: TddColors.surface2,
        borderRadius: _borderRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: TddTypography.sans(
          size: size * 0.4,
          weight: FontWeight.w600,
          color: TddColors.text2,
        ),
      ),
    );
  }
}
