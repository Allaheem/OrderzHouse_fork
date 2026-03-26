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

void main() async {
  // Step 1: Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2: Initialize app preferences (non-sensitive settings only)
  await AppPrefs.init();
  await RouteTracker.init();

  // Step 4: Initialize Hive for local cache (non-sensitive data only; no tokens)
  await Hive.initFlutter();
  await CacheService.init();

  // Step 5: Load environment variables (gracefully handle missing .env file)
  try {
    await dotenv.load(fileName: '.env');
    // ignore: avoid_print
    print('✅ Environment variables loaded successfully');
  } catch (e) {
    // .env file not found - initialize with empty data to avoid NotInitializedError
    // ignore: avoid_print
    print('⚠️ Warning: .env file not found, using defaults');
    dotenv.testLoad(fileInput: '');
  }

  // Step 6: Log baseUrl for debugging
  // ignore: avoid_print
  print('🌐 API Base URL: ${AppConfig.baseUrl}');

  // Step 7: Perform health check (non-blocking)
  unawaited(
    HealthCheckService.ping()
        .then((result) {
          if (result.success) {
            // ignore: avoid_print
            print('✅ ${result.message}');
          } else {
            // ignore: avoid_print
            print('❌ ${result.message}');
          }
        })
        .catchError((error) {
          // ignore: avoid_print
          print('❌ Health check error: $error');
        }),
  );

  // Step 8: Run app (only once)
  runApp(const ProviderScope(child: OrderzHouse()));
}

class OrderzHouse extends ConsumerWidget {
  const OrderzHouse({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale for automatic updates
    final locale = ref.watch(localeProvider);

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
