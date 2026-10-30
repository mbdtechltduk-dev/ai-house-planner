import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/app_banner_ad.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/common_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(localizationsProvider).t;

    final modules = [
      _ModuleData(t('floorPlan'), t('floorPlanSubtitle'), Icons.architecture, '/floor-plan'),
      _ModuleData(t('interiorDesign'), t('interiorDesignSubtitle'), Icons.chair_alt_outlined,
          '/interior-design'),
      _ModuleData(t('elevationDesign'), t('elevationDesignSubtitle'), Icons.villa_outlined,
          '/elevation-design'),
      _ModuleData(t('materialEstimation'), t('materialEstimationSubtitle'),
          Icons.calculate_outlined, '/material-estimation'),
      _ModuleData(t('costCalculator'), t('costCalculatorSubtitle'),
          Icons.price_change_outlined, '/cost-calculator'),
      _ModuleData(
          t('myProjects'), t('myProjectsSubtitle'), Icons.folder_open_outlined, '/projects'),      _ModuleData(t('settings'), t('settingsSubtitle'), Icons.settings_outlined, '/settings'),
    
  _ModuleData(
      t('goPremium'),
      t('premiumSubtitle'),
      Icons.workspace_premium_outlined,
      '/premium'),
];

    return Scaffold(
      appBar: AppBar(
        title: Text(t('appName')),actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            onPressed: () => context.push('/premium'),
          ),
        ],      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.95,
        ),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final m = modules[index];
          return ModuleCard(
            title: m.title,
            subtitle: m.subtitle,
            icon: m.icon,
            onTap: () async {
              // Interstitial ad logic: skip on the first major module
              // entered from Home, then alternate skip/show from there
              // (see AdsService.registerActionAndMaybeShow).
              await sl.adsService.registerActionAndMaybeShow();
              if (context.mounted) context.push(m.route);
            },
          );
        },
      ),
      bottomNavigationBar: const AppBannerAd(),
    );
  }
}

class _ModuleData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  _ModuleData(this.title, this.subtitle, this.icon, this.route);
}
