import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/ai_render_view.dart';
import '../../../../core/widgets/app_banner_ad.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../floor_plan/domain/entities/floor_plan_result.dart';
import '../../../floor_plan/domain/entities/room.dart';
import '../../../floor_plan/presentation/providers/floor_plan_providers.dart';
import '../providers/interior_design_providers.dart';

const _budgetLevels = ['Economy', 'Standard', 'Luxury'];

/// Room types that make sense to generate an interior render for -
/// excludes circulation/open-air spaces (hallway, entrance, car porch,
/// stairs, garden, etc.) which aren't "interiors" in the usual sense.
const _renderableTypes = {
  RoomType.bedroom,
  RoomType.masterBedroom,
  RoomType.bathroom,
  RoomType.attachedBathroom,
  RoomType.kitchen,
  RoomType.drawingRoom,
  RoomType.tvLounge,
  RoomType.dining,
  RoomType.store,
  RoomType.laundry,
};

class InteriorDesignScreen extends ConsumerStatefulWidget {
  const InteriorDesignScreen({super.key});

  @override
  ConsumerState<InteriorDesignScreen> createState() => _InteriorDesignScreenState();
}

class _InteriorDesignScreenState extends ConsumerState<InteriorDesignScreen> {
  String _style = AppConstants.interiorStyles.first;
  String _budgetLevel = 'Standard';
  Room? _selectedRoom;
  bool _historyLoadRequested = false;
  bool _isSavingProject = false;
  bool _isLoadingSuggestions = false;
  String? _suggestions;

  List<Room> _renderableRooms(FloorPlanResult plan) {
    return plan.floors
        .expand((f) => f.rooms)
        .where((r) => _renderableTypes.contains(r.type))
        .toList();
  }

  /// Auto-saves the project if it hasn't been saved yet (e.g. the user
  /// reached this screen some other way than the normal Floor Plan ->
  /// Continue flow, which already auto-saves). This guarantees Generate
  /// is never permanently blocked - it silently creates the project
  /// instead of leaving the button disabled with no clear next step.
  Future<String?> _ensureProjectSaved(FloorPlanResult plan) async {
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
    final interiorState = ref.watch(interiorDesignControllerProvider);
    final plan = floorPlanState.result;
    final t = ref.watch(localizationsProvider).t;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('interiorDesign'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(t('generateFloorPlanFirstShort')),
          ),
        ),
      );
    }

    final rooms = _renderableRooms(plan);
    _selectedRoom ??= rooms.isNotEmpty ? rooms.first : null;

    final projectId = floorPlanState.projectId;
    if (!_historyLoadRequested && projectId != null) {
      _historyLoadRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(interiorDesignControllerProvider.notifier).loadHistory(projectId);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('interiorDesign'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: t('usingFloorPlan'),
            icon: Icons.check_circle_outline,
            child: Text(plan.shortSummary),
          ),
          const SizedBox(height: 16),
          if (rooms.isNotEmpty)
            SectionCard(
              title: 'Room to Design',
              icon: Icons.meeting_room_outlined,
              child: DropdownButtonFormField<Room>(
                initialValue: _selectedRoom,
                isExpanded: true,
                items: rooms
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                              '${r.label} (${r.width.toStringAsFixed(0)}x${r.height.toStringAsFixed(0)} ft)'),
                        ))
                    .toList(),
                onChanged: (r) => setState(() => _selectedRoom = r),
              ),
            ),
          const SizedBox(height: 16),
          SectionCard(
            title: t('interiorStyle'),
            icon: Icons.palette_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.interiorStyles
                  .map((s) => ChoiceChip(
                        label: Text(s),
                        selected: _style == s,
                        onSelected: (_) => setState(() => _style = s),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Budget Level',
            icon: Icons.attach_money_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _budgetLevels
                  .map((b) => ChoiceChip(
                        label: Text(b),
                        selected: _budgetLevel == b,
                        onSelected: (_) => setState(() => _budgetLevel = b),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: t('generateInteriorRender'),
            icon: Icons.auto_awesome,
            isLoading: interiorState.isGenerating || _isSavingProject,
            onPressed: () async {
              final id = await _ensureProjectSaved(plan);
              if (id == null || !mounted) return;
              await ref.read(interiorDesignControllerProvider.notifier).generate(
                    projectId: id,
                    plan: plan,
                    style: _style,
                    targetRoom: _selectedRoom,
                    budgetLevel: _budgetLevel,
                  );
            },
          ),
          const SizedBox(height: 20),
          AIRenderView(
            isLoading: interiorState.isGenerating,
            filePath: interiorState.latest?.filePath,
            errorMessage: interiorState.errorMessage,
          ),
          if (interiorState.history.length > 1) ...[
            const SizedBox(height: 20),
            SectionCard(
              title: t('renderHistory'),
              icon: Icons.history,
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: interiorState.history.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final render = interiorState.history[index];
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
          const SizedBox(height: 20),
          SectionCard(
            title: 'AI Design Tips',
            icon: Icons.lightbulb_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _suggestions ??
                      'Get personalized suggestions for your $_style interior, based on this '
                          'project\'s floor plan.',
                  style: TextStyle(
                    color: _suggestions == null ? Colors.grey.shade600 : null,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: _isLoadingSuggestions
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_isLoadingSuggestions ? t('generate') : 'Get AI Design Tips'),
                  onPressed: _isLoadingSuggestions ? null : () => _fetchSuggestions(plan),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NextStepPrompt(
            question: t('promptElevation'),
            skipLabel: t('skip'),
            continueLabel: t('continueLabel'),
            onSkip: () => context.go('/home'),
            onContinue: () => context.push('/elevation-design'),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: const AppBannerAd(),
    );
  }

  Future<void> _fetchSuggestions(FloorPlanResult plan) async {
    setState(() => _isLoadingSuggestions = true);
    // Reuses the exact same shared AIService instance (sl.aiService) that
    // Interior/Elevation rendering already uses - no separate/duplicate AI
    // integration is created for suggestions.
    final roomContext = _selectedRoom != null ? ' Focus room: ${_selectedRoom!.label}.' : '';
    final result = await sl.aiService.getDesignSuggestions(
      context: 'Floor plan: ${plan.shortSummary}. Interior style: $_style.$roomContext',
      userPrompt: 'Suggest 3 concise, practical improvements for this interior design.',
    );
    if (!mounted) return;
    setState(() {
      _isLoadingSuggestions = false;
      _suggestions = result.success
          ? result.text
          : (result.errorMessage ?? 'AI suggestions are not available right now.');
    });
  }
}
