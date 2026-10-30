import 'dart:io';
import 'package:flutter/material.dart';
import 'common_widgets.dart';

/// Displays the outcome of an AIService image call: a skeleton while
/// loading, the rendered image (local file path or remote URL), or a
/// friendly message when AI is not configured / the call failed. This is
/// the only place image results from AIService are rendered, decoupled
/// from which provider produced them.
class AIRenderView extends StatelessWidget {
  final bool isLoading;
  final String? filePath;
  final String? errorMessage;

  const AIRenderView({
    super.key,
    required this.isLoading,
    this.filePath,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SkeletonBox(height: 260);
    }

    if (errorMessage != null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 28),
            const SizedBox(height: 8),
            Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    if (filePath == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('No render generated yet.'),
      );
    }

    final isRemote = filePath!.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: isRemote
          ? Image.network(filePath!, height: 280, width: double.infinity, fit: BoxFit.cover)
          : Image.file(File(filePath!), height: 280, width: double.infinity, fit: BoxFit.cover),
    );
  }
}
