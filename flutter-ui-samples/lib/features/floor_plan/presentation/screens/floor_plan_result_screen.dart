import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_banner_ad.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../providers/floor_plan_providers.dart';
import '../widgets/floor_plan_painter.dart';

class FloorPlanResultScreen extends ConsumerStatefulWidget {
  const FloorPlanResultScreen({super.key});

  @override
  ConsumerState<FloorPlanResultScreen> createState() => _FloorPlanResultScreenState();
}

class _FloorPlanResultScreenState extends ConsumerState<FloorPlanResultScreen> {
  int _selectedFloor = 0;
  bool _isSaving = false;

  Future<void> _save(BuildContext context, String Function(String) t) async {
    setState(() => _isSaving = true);
    final controller = ref.read(floorPlanControllerProvider.notifier);
    final name = 'Project ${DateTime.now().toString().substring(0, 16)}';
    final result = await controller.saveCurrent(projectName: name);
    if (!mounted) return;
    setState(() => _isSaving = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t('floorPlanSaved'))));
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message)));
      },
    );
  }

  /// Ensures the current floor plan is saved (creating the project
  /// transparently on first use if the user hasn't tapped the save icon
  /// yet) before moving on to Interior/Elevation design, which need a
  /// saved projectId to persist generated renders. Previously "Continue"
  /// navigated immediately without saving, so Interior/Elevation Design
  /// would find no projectId and disable their Generate button with no
  /// clear explanation - the user had to notice and tap the separate
  /// save icon first. This removes that dead end entirely: continuing
  /// the workflow always saves automatically, silently, with no extra
  /// tap required.
  Future<void> _ensureSavedThenGo(String route) async {
    final state = ref.read(floorPlanControllerProvider);
    if (state.projectId == null) {
      final name = 'Project ${DateTime.now().toString().substring(0, 16)}';
      await ref.read(floorPlanControllerProvider.notifier).saveCurrent(projectName: name);
    }
    if (!mounted) return;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(floorPlanControllerProvider);
    final plan = state.result;
    final t = ref.watch(localizationsProvider).t;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('floorPlan'))),
        body: Center(child: Text(t('noFloorPlanGenerated'))),
      );
    }

    final floor = plan.floors[_selectedFloor];

    return Scaffold(
      appBar: AppBar(
        title: Text(t('floorPlan')),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            onPressed: _isSaving ? null : () => _save(context, t),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (plan.floors.length > 1)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: plan.floors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = index == _selectedFloor;
                  return ChoiceChip(
                    label: Text(index == 0 ? 'Ground Floor' : 'Floor $index'),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedFloor = index),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          SectionCard(
            title: t('summary'),
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.shortSummary),
                const SizedBox(height: 6),
                Text('${t('coveredArea')}: ${plan.totalCoveredAreaSqFt.toStringAsFixed(0)} sq ft'),
                Text('Plot area: ${plan.plotAreaSqFt.toStringAsFixed(0)} sq ft'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: AspectRatio(
              aspectRatio: plan.plotWidthFeet / plan.plotLengthFeet,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CustomPaint(
                  painter: FloorPlanPainter(
                    floor: floor,
                    plotWidthFeet: plan.plotWidthFeet,
                    plotLengthFeet: plan.plotLengthFeet,
                    wallThicknessInches: plan.wallThicknessInches,
                  ),
                  child: Container(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: t('roomsOnThisFloor'),
            icon: Icons.list_alt,
            child: Column(
              children: floor.rooms
                  .map((r) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.square_foot, size: 18),
                        title: Text(r.label),
                        trailing: Text(
                            '${r.width.toStringAsFixed(0)}x${r.height.toStringAsFixed(0)} ft (${r.areaSqFt.toStringAsFixed(0)} sqft)'),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          NextStepPrompt(
            question: t('promptInterior'),
            skipLabel: t('skip'),
            continueLabel: t('continueLabel'),
            onSkip: () => context.go('/home'),
            onContinue: () => _ensureSavedThenGo('/interior-design'),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: const AppBannerAd(),
    );
  }
}
