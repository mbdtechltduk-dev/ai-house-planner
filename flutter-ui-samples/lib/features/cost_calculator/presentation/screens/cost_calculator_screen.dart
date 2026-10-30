import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/currency_provider.dart';
import '../../../../core/widgets/app_banner_ad.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../material_estimation/domain/entities/material_estimate.dart';
import '../../../material_estimation/presentation/providers/material_estimation_providers.dart';
import '../../domain/entities/cost_estimate.dart';
import '../providers/cost_calculator_providers.dart';

/// Cost Calculator is a guided, explicit sequence rather than a screen
/// that silently pre-fills numbers and shows a total before the user has
/// consciously provided anything:
///   1. Country
///   2. Currency (defaulted from country, editable)
///   3. Market prices (defaulted from currency, editable)
///   4. Calculated breakdown + grand total
enum _Step { country, currency, prices, result }

class CostCalculatorScreen extends ConsumerStatefulWidget {
  const CostCalculatorScreen({super.key});

  @override
  ConsumerState<CostCalculatorScreen> createState() => _CostCalculatorScreenState();
}

class _CostCalculatorScreenState extends ConsumerState<CostCalculatorScreen> {
  final _brick = TextEditingController();
  final _cement = TextEditingController();
  final _steel = TextEditingController();
  final _sand = TextEditingController();
  final _crush = TextEditingController();
  final _paint = TextEditingController();
  final _tile = TextEditingController();
  final _labour = TextEditingController();
  bool _includeLabour = true;

  Country? _country;
  AppCurrency? _currency;
  _Step _step = _Step.country;

  late final List<TextEditingController> _allControllers = [
    _brick, _cement, _steel, _sand, _crush, _paint, _tile, _labour,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _allControllers) {
      c.addListener(_recalculate);
    }
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.removeListener(_recalculate);
      c.dispose();
    }
    super.dispose();
  }

  void _applyPresetsFor(AppCurrency currency) {
    final preset = CurrencyPricePresets.forCurrency(currency);
    _brick.text = preset['brick']!.toString();
    _cement.text = preset['cement']!.toString();
    _steel.text = preset['steel']!.toString();
    _sand.text = preset['sand']!.toString();
    _crush.text = preset['crush']!.toString();
    _paint.text = preset['paint']!.toString();
    _tile.text = preset['tile']!.toString();
    _labour.text = preset['labour']!.toString();
  }

  void _recalculate() {
    final materials = ref.read(materialEstimationControllerProvider).estimate;
    if (materials == null || _currency == null) return;
    final prices = MaterialPrices(
      brickPricePerUnit: double.tryParse(_brick.text) ?? 0,
      cementPricePerBag: double.tryParse(_cement.text) ?? 0,
      steelPricePerKg: double.tryParse(_steel.text) ?? 0,
      sandPricePerCft: double.tryParse(_sand.text) ?? 0,
      crushPricePerCft: double.tryParse(_crush.text) ?? 0,
      paintPricePerSqFt: double.tryParse(_paint.text) ?? 0,
      tilePricePerSqFt: double.tryParse(_tile.text) ?? 0,
      labourPricePerSqFt: _includeLabour ? (double.tryParse(_labour.text) ?? 0) : 0,
    );
    final controller = ref.read(costCalculatorControllerProvider.notifier);
    controller.updatePrices(prices);
    controller.calculate(materials);
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(materialEstimationControllerProvider).estimate;
    final costState = ref.watch(costCalculatorControllerProvider);
    final t = ref.watch(localizationsProvider).t;

    if (materials == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('costCalculator'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(t('runMaterialEstimationFirst')),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('costCalculator'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StepProgress(current: _step),
          const SizedBox(height: 20),
          if (_step == _Step.country) _buildCountryStep(),
          if (_step == _Step.currency) _buildCurrencyStep(t),
          if (_step == _Step.prices) _buildPricesStep(t),
          if (_step == _Step.result) _buildResultStep(context, costState, t),
        ],
      ),
      bottomNavigationBar: const AppBannerAd(),
    );
  }

  Widget _buildCountryStep() {
    return SectionCard(
      title: 'Which country are you building in?',
      icon: Icons.public_outlined,
      child: Column(
        children: [
          ...Country.values.map((c) => RadioListTile<Country>(
                contentPadding: EdgeInsets.zero,
                title: Text(c.displayName),
                value: c,
                groupValue: _country,
                onChanged: (v) => setState(() => _country = v),
              )),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Next: Choose Currency',
            onPressed: _country == null
                ? null
                : () {
                    setState(() {
                      _currency = _country!.defaultCurrency;
                      _step = _Step.currency;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyStep(String Function(String) t) {
    return SectionCard(
      title: 'Confirm your currency',
      icon: Icons.attach_money_outlined,
      child: Column(
        children: [
          ...AppCurrency.values.map((c) => RadioListTile<AppCurrency>(
                contentPadding: EdgeInsets.zero,
                title: Text(c.displayName),
                value: c,
                groupValue: _currency,
                onChanged: (v) => setState(() => _currency = v),
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = _Step.country),
                  child: Text(t('back')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Next: Market Prices',
                  onPressed: _currency == null
                      ? null
                      : () {
                          ref.read(currencyProvider.notifier).setCurrency(_currency!);
                          _applyPresetsFor(_currency!);
                          setState(() => _step = _Step.prices);
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricesStep(String Function(String) t) {
    final currency = _currency!;
    return SectionCard(
      title: t('enterLocalPrices'),
      icon: Icons.price_change_outlined,
      child: Column(
        children: [
          Text(
            'These are typical prices for ${currency.code} - edit any field to match '
            'your local supplier quotes.',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          _priceField(t('priceBrick'), _brick, currency),
          _priceField(t('priceCement'), _cement, currency),
          _priceField(t('priceSteel'), _steel, currency),
          _priceField(t('priceSand'), _sand, currency),
          _priceField(t('priceCrush'), _crush, currency),
          _priceField(t('pricePaint'), _paint, currency),
          _priceField(t('priceTile'), _tile, currency),
          const Divider(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t('includeLabourCost')),
            value: _includeLabour,
            onChanged: (v) => setState(() => _includeLabour = v),
          ),
          if (_includeLabour) _priceField(t('priceLabour'), _labour, currency),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = _Step.currency),
                  child: Text(t('back')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: t('recalculate'),
                  icon: Icons.calculate_outlined,
                  onPressed: () {
                    _recalculate();
                    setState(() => _step = _Step.result);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultStep(
    BuildContext context,
    CostCalculatorState costState,
    String Function(String) t,
  ) {
    final currency = _currency!;
    final estimate = costState.estimate;
    return Column(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit prices'),
          onPressed: () => setState(() => _step = _Step.prices),
        ),
        const SizedBox(height: 12),
        if (estimate != null) _buildResults(context, estimate, t, currency),
        const SizedBox(height: 24),
        NextStepPrompt(
          question: t('promptSaveProject'),
          skipLabel: t('skip'),
          continueLabel: t('goToProjects'),
          onSkip: () => context.go('/home'),
          onContinue: () => context.push('/projects'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _priceField(String label, TextEditingController controller, AppCurrency currency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, prefixText: '${currency.symbol} '),
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    CostEstimate estimate,
    String Function(String) t,
    AppCurrency currency,
  ) {
    return Column(
      children: [
        SectionCard(
          title: t('costBreakdown'),
          icon: Icons.receipt_long_outlined,
          child: Column(
            children: estimate.lineItems
                .where((i) => i.label != 'Labour' || _includeLabour)
                .map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text('${i.label} (${i.quantity.toStringAsFixed(1)} ${i.unit})')),
                          Expanded(
                              flex: 2,
                              child: Text(currency.format(i.total),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _totalRow(t('materialCost'), currency.format(estimate.materialCost)),
                if (_includeLabour)
                  _totalRow(t('labourCost'), currency.format(estimate.labourCost)),
                const Divider(color: Colors.white54),
                _totalRow(
                  t('grandTotal'),
                  currency.format(
                    _includeLabour ? estimate.grandTotal : estimate.materialCost,
                  ),
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false}) {
    final style = TextStyle(
      color: Colors.white,
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      fontSize: isBold ? 18 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  final _Step current;
  const _StepProgress({required this.current});

  @override
  Widget build(BuildContext context) {
    const labels = ['Country', 'Currency', 'Prices', 'Total'];
    final currentIndex = _Step.values.indexOf(current);
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = i <= currentIndex;
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                child: Text('${i + 1}',
                    style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade600, fontSize: 12)),
              ),
              const SizedBox(height: 4),
              Text(labels[i], style: const TextStyle(fontSize: 10.5)),
            ],
          ),
        );
      }),
    );
  }
}
