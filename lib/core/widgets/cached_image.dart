import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      height: height,
      width: width,
      placeholder: (_, __) => _ShimmerBox(
        height: height,
        width: width,
        borderRadius: borderRadius,
      ),
      errorWidget: (_, __, ___) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class ProfileImage extends StatelessWidget {
  const ProfileImage({
    super.key,
    required this.displayName,
    this.imageUrl,
    this.size = 44,
  });

  final String displayName;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(displayName);

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        child: Text(initials),
      );
    }

    return ClipOval(
      child: CachedImage(
        url: imageUrl!,
        height: size,
        width: size,
        fit: BoxFit.cover,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.height, this.width, this.borderRadius});

  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
