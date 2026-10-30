import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/app_banner_ad.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/floor_plan_input.dart';
import '../providers/floor_plan_providers.dart';

class FloorPlanInputScreen extends ConsumerStatefulWidget {
  const FloorPlanInputScreen({super.key});

  @override
  ConsumerState<FloorPlanInputScreen> createState() => _FloorPlanInputScreenState();
}

class _FloorPlanInputScreenState extends ConsumerState<FloorPlanInputScreen> {
  final _formKey = GlobalKey<FormState>();

  final _widthCtrl = TextEditingController(text: '30');
  final _lengthCtrl = TextEditingController(text: '60');
  String _unit = 'Feet';
  String _facing = 'North';
  int _floors = 1;
  int _bedrooms = 3;
  int _bathrooms = 2;
  int _attachedBaths = 1;
  bool _kitchen = true;
  bool _drawingRoom = true;
  bool _tvLounge = false;
  bool _dining = false;
  bool _store = false;
  bool _laundry = false;
  bool _carPorch = true;
  bool _garage = false;
  bool _porch = false;
  bool _terrace = false;
  bool _balcony = false;
  bool _stair = false;
  bool _garden = false;
  bool _showAdvanced = false;
  final _wallThicknessCtrl = TextEditingController();
  final _corridorWidthCtrl = TextEditingController();

  @override
  void dispose() {
    _widthCtrl.dispose();
    _lengthCtrl.dispose();
    _wallThicknessCtrl.dispose();
    _corridorWidthCtrl.dispose();
    super.dispose();
  }

  void _onGenerate() {
    if (!_formKey.currentState!.validate()) return;

    final input = FloorPlanInput(
      plotWidth: double.parse(_widthCtrl.text),
      plotLength: double.parse(_lengthCtrl.text),
      unit: _unit,
      plotFacing: _facing,
      floors: _floors,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      attachedBathrooms: _attachedBaths,
      kitchen: _kitchen,
      drawingRoom: _drawingRoom,
      tvLounge: _tvLounge,
      dining: _dining,
      store: _store,
      laundry: _laundry,
      carPorch: _carPorch,
      garage: _garage,
      porch: _porch,
      terrace: _terrace,
      balcony: _balcony,
      stair: _stair || _floors > 1,
      garden: _garden,
      wallThicknessInches: double.tryParse(_wallThicknessCtrl.text),
      corridorWidthFeet: double.tryParse(_corridorWidthCtrl.text),
    );

    ref.read(floorPlanControllerProvider.notifier).generate(input).then((_) {
      if (!mounted) return;
      final state = ref.read(floorPlanControllerProvider);
      if (state.result != null) {
        context.push('/floor-plan/result');
      } else if (state.errorMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGenerating = ref.watch(floorPlanControllerProvider).isGenerating;
    final t = ref.watch(localizationsProvider).t;

    return Scaffold(
      appBar: AppBar(title: Text(t('floorPlan'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: t('plotDetails'),
              icon: Icons.crop_square,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _widthCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Plot Width'),
                          validator: _positiveNumberValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lengthCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Plot Length'),
                          validator: _positiveNumberValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: AppConstants.plotUnits
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _facing,
                    decoration: const InputDecoration(labelText: 'Plot Facing'),
                    items: AppConstants.plotFacings
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setState(() => _facing = v!),
                  ),
                  const SizedBox(height: 12),
                  _StepperRow(
                    label: 'Number of Floors',
                    value: _floors,
                    min: 1,
                    max: 6,
                    onChanged: (v) => setState(() => _floors = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: t('rooms'),
              icon: Icons.meeting_room_outlined,
              child: Column(
                children: [
                  _StepperRow(
                    label: 'Bedrooms',
                    value: _bedrooms,
                    min: 1,
                    max: 10,
                    onChanged: (v) => setState(() => _bedrooms = v),
                  ),
                  _StepperRow(
                    label: 'Bathrooms',
                    value: _bathrooms,
                    min: 1,
                    max: 8,
                    onChanged: (v) => setState(() => _bathrooms = v),
                  ),
                  _StepperRow(
                    label: 'Attached Bathrooms',
                    value: _attachedBaths,
                    min: 0,
                    max: 6,
                    onChanged: (v) => setState(() => _attachedBaths = v),
                  ),
                  const Divider(height: 24),
                  _SwitchRow(label: 'Kitchen', value: _kitchen, onChanged: (v) => setState(() => _kitchen = v)),
                  _SwitchRow(label: 'Drawing Room', value: _drawingRoom, onChanged: (v) => setState(() => _drawingRoom = v)),
                  _SwitchRow(label: 'TV Lounge', value: _tvLounge, onChanged: (v) => setState(() => _tvLounge = v)),
                  _SwitchRow(label: 'Dining', value: _dining, onChanged: (v) => setState(() => _dining = v)),
                  _SwitchRow(label: 'Store', value: _store, onChanged: (v) => setState(() => _store = v)),
                  _SwitchRow(label: 'Laundry', value: _laundry, onChanged: (v) => setState(() => _laundry = v)),
                  _SwitchRow(label: 'Car Porch', value: _carPorch, onChanged: (v) => setState(() => _carPorch = v)),
                  _SwitchRow(label: 'Garage', value: _garage, onChanged: (v) => setState(() => _garage = v)),
                  _SwitchRow(label: 'Porch', value: _porch, onChanged: (v) => setState(() => _porch = v)),
                  _SwitchRow(label: 'Terrace', value: _terrace, onChanged: (v) => setState(() => _terrace = v)),
                  _SwitchRow(label: 'Balcony', value: _balcony, onChanged: (v) => setState(() => _balcony = v)),
                  _SwitchRow(label: 'Stair', value: _stair || _floors > 1, onChanged: _floors > 1 ? null : (v) => setState(() => _stair = v)),
                  _SwitchRow(label: 'Garden', value: _garden, onChanged: (v) => setState(() => _garden = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(t('advancedSettings')),
                    subtitle: const Text('Optional engineering overrides'),
                    value: _showAdvanced,
                    onChanged: (v) => setState(() => _showAdvanced = v),
                  ),
                  if (_showAdvanced)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _wallThicknessCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Wall Thickness (inches)',
                              hintText: 'Default: 9',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _corridorWidthCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Corridor Width (ft)',
                              hintText: 'Default: engine-calculated',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: t('generateFloorPlan'),
              icon: Icons.auto_awesome,
              isLoading: isGenerating,
              onPressed: _onGenerate,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const AppBannerAd(),
    );
  }

  String? _positiveNumberValidator(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Enter a valid number';
    return null;
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}
