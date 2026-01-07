import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/widgets/cached_image.dart';

class ImagePickerGrid extends StatelessWidget {
  const ImagePickerGrid({
    super.key,
    this.uploadedUrls = const <String>[],
    this.localFiles = const <File>[],
    required this.onImagesChanged,
    required this.onRemoveUrl,
    this.maxImages = 5,
  });

  final List<String> uploadedUrls;
  final List<File> localFiles;
  final ValueChanged<List<File>> onImagesChanged;
  final ValueChanged<String> onRemoveUrl;
  final int maxImages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final total = uploadedUrls.length + localFiles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Photos', style: theme.textTheme.titleMedium),
            const Spacer(),
            Text('$total/$maxImages', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 10),
        if (total == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No photos selected.',
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: total,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index < uploadedUrls.length) {
                final url = uploadedUrls[index];
                final thumb = CloudinaryService.getItemThumbUrl(url);
                return _Tile(
                  child: CachedImage(
                    url: thumb,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onRemove: () => onRemoveUrl(url),
                );
              }

              final fileIndex = index - uploadedUrls.length;
              final file = localFiles[fileIndex];

              return _Tile(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(file, fit: BoxFit.cover),
                ),
                onRemove: () {
                  final next = List<File>.of(localFiles)..removeAt(fileIndex);
                  onImagesChanged(next);
                },
              );
            },
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
