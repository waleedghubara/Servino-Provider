import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:servino_provider/core/ads/ads_manager.dart';
import 'package:servino_provider/firebase_options.dart';
import 'core/routes/app_router.dart';
import 'core/routes/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';
import 'core/localization/localization_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:servino_provider/features/notifications/providers/notification_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/services/firebase_messaging_service.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:servino_provider/core/services/security_service.dart';
import 'package:servino_provider/core/widgets/security.dart';
import 'package:dio/dio.dart';
import 'package:servino_provider/core/api/dio_consumer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:servino_provider/core/utils/lifecycle_manager.dart'; // Added import
import 'package:hive_flutter/hive_flutter.dart';
import 'package:servino_provider/core/cache/cache_helper.dart';
import 'package:servino_provider/features/auth/data/models/user_model.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'dart:convert';
import 'package:servino_provider/core/services/call/zego_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await ThemeManager().initTheme();
  // AdsMode.production
  AdsManager.instance.setAdsMode(AdsMode.disabled);
  await AdsManager.instance.initialize();

  await EasyLocalization.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Notifications
  await FirebaseMessagingService().initNotifications();

  // Setup Zego Navigator Key
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  // Init Zego Synchronously if logged in
  final userJson = await SecureCacheHelper().getDataString(key: 'user_data');
  if (userJson != null) {
    try {
      final cachedUser = UserModel.fromJson(jsonDecode(userJson));
      await ZegoService().onUserLogin(
        cachedUser.id.toString(),
        cachedUser.name,
        cachedUser.profileImage,
      );
    } catch (e) {
      // Handle decode error
    }
  }

  // Enable Offline Calling (CallKit/SystemUI)
  ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI([
    ZegoUIKitSignalingPlugin(),
  ]);

  // Fix AudioContextIOS assertion error for Zego on iOS
  try {
    AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  } catch (e) {
    debugPrint('Error setting global audio context: $e');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Security Checks
  final securityService = SecurityService();
  try {
    // Enable SSL Pinning immediately
    // await securityService.pinSSL(); // Uncomment when certificates are ready

    final isSafe = await securityService.runSecurityChecks();
    if (!isSafe) {
      runApp(
        EasyLocalization(
          supportedLocales: LocalizationManager.supportedLocales,
          path: LocalizationManager.translationsPath,
          fallbackLocale: LocalizationManager.fallbackLocale,
          startLocale: LocalizationManager.fallbackLocale,
          child: const SecurityBlockerApp(),
        ),
      );
      return;
    }
  } catch (e) {
    debugPrint('Security check failed with error: $e');
    // Decide whether to block or allow based on error policy.
    // For now, it continues to runApp if not explicitly blocked.
  }

  runApp(
    EasyLocalization(
      supportedLocales: LocalizationManager.supportedLocales,
      path: LocalizationManager.translationsPath,
      fallbackLocale: LocalizationManager.fallbackLocale,
      startLocale: LocalizationManager.fallbackLocale,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(api: DioConsumer(dio: Dio())),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeManager().themeModeNotifier,
            builder: (context, mode, child) {
              return MaterialApp(
                title: 'Servino Provider',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: mode,
                navigatorKey: navigatorKey,
                initialRoute: Routes.splash,
                onGenerateRoute: AppRouter.generateRoute,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                builder: (context, child) {
                  return LifecycleManager(
                    userId: Provider.of<UserProvider>(
                      context,
                    ).user?.id.toString(),
                    role: 'provider',
                    child: Stack(
                      children: [
                        child!,

                        /// support minimizing
                        ZegoUIKitPrebuiltCallMiniOverlayPage(
                          contextQuery: () {
                            return navigatorKey.currentState!.context;
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
