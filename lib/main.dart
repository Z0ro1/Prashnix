import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/config/supabase_config.dart';
import 'core/database/database_service.dart';
import 'core/services/sync_queue_service.dart';
import 'core/theme/app_colors.dart';
import 'core/widgets/global_error_boundary.dart';
import 'core/widgets/root_navigator.dart';
import 'features/profile/presentation/providers/settings_provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database
  final dbService = DatabaseService();
  await dbService.database;

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Defer non-critical SDKs to avoid slowing down first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    MobileAds.instance.initialize();
    SyncQueueService().initialize();
  });

  runApp(
    const ProviderScope(
      child: SpardhaApp(),
    ),
  );
}

class SpardhaApp extends ConsumerWidget {
  const SpardhaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return GlobalErrorBoundary(
      child: MaterialApp(
        title: 'Spardha Sprint',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: const RootNavigator(),
      ),
    );
  }
}
