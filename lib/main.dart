import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'core/config/supabase_config.dart';
import 'core/database/database_service.dart';
import 'core/services/sync_queue_service.dart';
import 'core/services/widget_sync_service.dart';
import 'core/services/ad_service.dart';
import 'core/widgets/global_error_boundary.dart';
import 'core/navigation/app_router.dart';
import 'features/profile/presentation/providers/settings_provider.dart';
import 'features/gamification/presentation/widgets/app_lifecycle_heart_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database and Supabase concurrently (cuts bootstrap time in half)
  await Future.wait([
    DatabaseService().database,
    SupabaseConfig.initialize(),
    WidgetSyncService.initialize(),
  ]);

  // Defer non-critical hardware & SDK configurations after the first frame renders
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Set 120Hz / High Refresh Rate on Android (non-blocking)
    if (Platform.isAndroid) {
      try {
        await FlutterDisplayMode.setHighRefreshRate();
      } catch (e) {
        debugPrint('Failed to set high refresh rate: $e');
      }
    }

    if (Platform.isAndroid || Platform.isIOS) {
      await MobileAds.instance.initialize();
      AdMobService().preLoadAds();
    }
    SyncQueueService().initialize();
  });

  runApp(
    const ProviderScope(
      child: PrashnixApp(),
    ),
  );
}

class PrashnixApp extends ConsumerWidget {
  const PrashnixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return GlobalErrorBoundary(
      child: MaterialApp.router(
        builder: (context, child) => AppLifecycleHeartHandler(
          child: OfflineWrapper(child: child!),
        ),
        title: 'Prashnix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('mr'), // Marathi
        ],
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
