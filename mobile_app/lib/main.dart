// ??? ????????
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart' show goRouterProvider;
import 'core/network/health_check_service.dart';
import 'core/config/app_config.dart';
import 'core/providers/locale_provider.dart';
import 'core/storage/app_prefs.dart';
import 'core/routing/route_tracker.dart';
import 'core/cache/cache_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/utils/app_debug_log.dart';

void main() async {
  // Step 1: Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2: Initialize app preferences (non-sensitive settings only)
  await AppPrefs.init();
  await RouteTracker.init();

  // Step 4: Initialize Hive for local cache (non-sensitive data only; no tokens).
  // On some iOS Simulator betas, path_provider/Hive FFI can throw — continue without disk cache.
  try {
    await Hive.initFlutter();
    await CacheService.init();
  } catch (e, _) {
    appDebugLog('⚠️ Hive/cache init failed (app runs without local cache): $e');
  }

  // Step 5: Load environment variables (gracefully handle missing .env file)
  try {
    await dotenv.load(fileName: '.env');
    appDebugLog('✅ Environment variables loaded successfully');
  } catch (e) {
    dotenv.testLoad(fileInput: '');
    appDebugLog('⚠️ Warning: .env file not found, using defaults');
  }

  appDebugLog('🌐 API Base URL: ${AppConfig.baseUrl}');

  unawaited(
    HealthCheckService.ping()
        .then((result) {
          if (result.success) {
            appDebugLog('✅ ${result.message}');
          } else {
            appDebugLog('❌ ${result.message}');
          }
        })
        .catchError((error) {
          appDebugLog('❌ Health check error: $error');
        }),
  );

  // Step 8: Run app (only once). Real device size / pixel ratio are available after the
  // first frame via MediaQuery; ScreenUtilInit below rescales from designSize on each build.
  runApp(const ProviderScope(child: OrderzHouse()));
}

class OrderzHouse extends ConsumerWidget {
  const OrderzHouse({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale for automatic updates
    final locale = ref.watch(localeProvider);

    // Baseline design (phone); .w / .h / .sp scale from this. splitScreenMode helps iPad
    // split view & foldables. Layout that must follow window width should use
    // MediaQuery / LayoutBuilder / AppContentLayout (see core/ui/screenutil_helpers.dart).
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'OrderzHouse',
        theme: AppTheme.lightTheme(context),
        routerConfig: ref.watch(goRouterProvider),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );
  }
}
