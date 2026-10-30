import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/ai_render_view.dart';
import '../../../../core/widgets/app_banner_ad.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../floor_plan/presentation/providers/floor_plan_providers.dart';
import '../providers/elevation_design_providers.dart';

class ElevationDesignScreen extends ConsumerStatefulWidget {
  const ElevationDesignScreen({super.key});

  @override
  ConsumerState<ElevationDesignScreen> createState() => _ElevationDesignScreenState();
}

class _ElevationDesignScreenState extends ConsumerState<ElevationDesignScreen> {
  String _style = AppConstants.elevationStyles.first;
  bool _historyLoadRequested = false;
  bool _isSavingProject = false;

  Future<String?> _ensureProjectSaved() async {
    final current = ref.read(floorPlanControllerProvider).projectId;
    if (current != null) return current;

    setState(() => _isSavingProject = true);
    final name = 'Project ${DateTime.now().toString().substring(0, 16)}';
    final result = await ref
        .read(floorPlanControllerProvider.notifier)
        .saveCurrent(projectName: name);
    if (mounted) setState(() => _isSavingProject = false);
    return result.dataOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final floorPlanState = ref.watch(floorPlanControllerProvider);
    final elevationState = ref.watch(elevationDesignControllerProvider);
    final plan = floorPlanState.result;
    final projectId = floorPlanState.projectId;
    final t = ref.watch(localizationsProvider).t;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('elevationDesign'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(t('generateFloorPlanFirstShort')),
          ),
        ),
      );
    }

    if (!_historyLoadRequested && projectId != null) {
      _historyLoadRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(elevationDesignControllerProvider.notifier).loadHistory(projectId);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('elevationDesign'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: t('usingFloorPlan'),
            icon: Icons.check_circle_outline,
            child: Text(plan.shortSummary),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: t('elevationStyle'),
            icon: Icons.villa_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.elevationStyles
                  .map((s) => ChoiceChip(
                        label: Text(s),
                        selected: _style == s,
                        onSelected: (_) => setState(() => _style = s),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: t('generateElevationRender'),
            icon: Icons.auto_awesome,
            isLoading: elevationState.isGenerating || _isSavingProject,
            onPressed: () async {
              final id = await _ensureProjectSaved();
              if (id == null || !mounted) return;
              await ref.read(elevationDesignControllerProvider.notifier).generate(
                    projectId: id,
                    plan: plan,
                    style: _style,
                  );
            },
          ),
          const SizedBox(height: 20),
          AIRenderView(
            isLoading: elevationState.isGenerating,
            filePath: elevationState.latest?.filePath,
            errorMessage: elevationState.errorMessage,
          ),
          if (elevationState.history.length > 1) ...[
            const SizedBox(height: 20),
            SectionCard(
              title: t('renderHistory'),
              icon: Icons.history,
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: elevationState.history.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final render = elevationState.history[index];
                    final isRemote = render.filePath.startsWith('http');
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: isRemote
                          ? Image.network(render.filePath, width: 100, height: 100, fit: BoxFit.cover)
                          : Image.file(File(render.filePath),
                              width: 100, height: 100, fit: BoxFit.cover),
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          NextStepPrompt(
            question: t('promptMaterial'),
            skipLabel: t('skip'),
            continueLabel: t('continueLabel'),
            onSkip: () => context.go('/home'),
            onContinue: () => context.push('/material-estimation'),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: const AppBannerAd(),
    );
  }
}
