import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A titled card container used throughout input/result screens for a
/// consistent, modern grouped-form look.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;

  const SectionCard({super.key, required this.title, required this.child, this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading placeholder for image/data-heavy sections.
class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const SkeletonBox({super.key, required this.height, this.width, this.borderRadius = 16});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A dashboard-style module card used on the Home screen.
class ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const ModuleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (color ?? scheme.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color ?? scheme.primary),
              ),
              const SizedBox(height: 14),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard "what would you like to do next?" prompt used after every
/// module completes (Skip / Continue pattern from the spec).
class NextStepPrompt extends StatelessWidget {
  final String question;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final String continueLabel;
  final String skipLabel;

  const NextStepPrompt({
    super.key,
    required this.question,
    required this.onSkip,
    required this.onContinue,
    this.continueLabel = 'Continue',
    this.skipLabel = 'Skip',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(question,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: onSkip, child: Text(skipLabel)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(onPressed: onContinue, child: Text(continueLabel)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
