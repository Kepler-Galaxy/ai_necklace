import 'dart:async';

import 'package:authing_sdk_v3/authing.dart';
import 'package:authing_sdk_v3/client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foxxy_package/backend/auth.dart';
import 'package:foxxy_package/backend/preferences.dart';
import 'package:foxxy_package/env/dev_env.dart';
import 'package:foxxy_package/env/env.dart';
import 'package:foxxy_package/env/prod_env.dart';
import 'package:foxxy_package/firebase_options_dev.dart' as dev;
import 'package:foxxy_package/firebase_options_prod.dart' as prod;
import 'package:foxxy_package/flavors.dart';
import 'package:foxxy_package/pages/home/page.dart';
import 'package:foxxy_package/pages/memory_detail/memory_detail_provider.dart';
import 'package:foxxy_package/pages/onboarding/wrapper.dart';
import 'package:foxxy_package/providers/auth_provider.dart';
import 'package:foxxy_package/providers/calendar_provider.dart';
import 'package:foxxy_package/providers/capture_provider.dart';
import 'package:foxxy_package/providers/connectivity_provider.dart';
import 'package:foxxy_package/providers/device_provider.dart';
import 'package:foxxy_package/providers/home_provider.dart';
import 'package:foxxy_package/providers/memory_provider.dart';
import 'package:foxxy_package/providers/message_provider.dart';
import 'package:foxxy_package/providers/onboarding_provider.dart';
import 'package:foxxy_package/providers/plugin_provider.dart';
import 'package:foxxy_package/providers/speech_profile_provider.dart';
import 'package:foxxy_package/services/notification_service.dart';
import 'package:foxxy_package/services/services.dart';
import 'package:foxxy_package/utils/analytics/gleap.dart';
import 'package:foxxy_package/utils/analytics/growthbook.dart';
import 'package:foxxy_package/utils/analytics/mixpanel.dart';
import 'package:foxxy_package/utils/features/calendar.dart';
import 'package:foxxy_package/utils/logger.dart';
import 'package:gleap_sdk/gleap_sdk.dart';
import 'package:instabug_flutter/instabug_flutter.dart';
import 'package:intercom_flutter/intercom_flutter.dart';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:foxxy_package/providers/diary_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';

Future<bool> _init() async {
  // Service manager
  ServiceManager.init();

  // TODO: thinh, move to app start
  await ServiceManager.instance().start();

  // Firebase
  ble.FlutterBluePlus.setLogLevel(ble.LogLevel.info, color: true);

  await Authing.init(Env.authingUserPoolId!, Env.authingAppId!);
  if (F.env == Environment.prod) {
    await Firebase.initializeApp(
        options: prod.DefaultFirebaseOptions.currentPlatform, name: 'prod');
  } else {
    await Firebase.initializeApp(
        options: dev.DefaultFirebaseOptions.currentPlatform, name: 'dev');
  }

  if (Env.intercomAppId != null) {
    await Intercom.instance.initialize(
      Env.intercomAppId!,
      iosApiKey: Env.intercomIOSApiKey,
      androidApiKey: Env.intercomAndroidApiKey,
    );
  }
  await NotificationService.instance.initialize();
  await SharedPreferencesUtil.init();
  await AuthenticationProvider.authingInit();
  await MixpanelManager.init();
  if (Env.gleapApiKey != null) Gleap.initialize(token: Env.gleapApiKey!);

  // TODO: replace by authing
  // listenAuthTokenChanges();
  bool isAuth = false;
  try {
    isAuth = (await getIdToken()) != "";
  } catch (e) {} // if no connect this will fail
  if (isAuth) MixpanelManager().identify();
  if (isAuth) identifyGleap();
  initOpus(await opus_flutter.load());

  await GrowthbookUtil.init();
  CalendarUtil.init();
  ble.FlutterBluePlus.setLogLevel(ble.LogLevel.info, color: true);
  return isAuth;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (F.env == Environment.prod) {
    Env.init(ProdEnv());
  } else {
    Env.init(DevEnv());
  }
  FlutterForegroundTask.initCommunicationPort();
  // _setupAudioSession();
  bool isAuth = await _init();
  if (Env.instabugApiKey != null) {
    Instabug.setWelcomeMessageMode(WelcomeMessageMode.disabled);
    runZonedGuarded(
      () async {
        Instabug.init(
          token: Env.instabugApiKey!,
          // invocationEvents: [InvocationEvent.shake, InvocationEvent.screenshot],
          invocationEvents: [],
        );
        if (isAuth) {
          Instabug.identifyUser(
            FirebaseAuth.instance.currentUser?.email ?? '',
            SharedPreferencesUtil().fullName,
            SharedPreferencesUtil().uid,
          );
        }
        FlutterError.onError = (FlutterErrorDetails details) {
          Zone.current.handleUncaughtError(
              details.exception, details.stack ?? StackTrace.empty);
        };
        Instabug.setColorTheme(ColorTheme.dark);
        runApp(const MyApp());
      },
      CrashReporting.reportCrash,
    );
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  // The navigator key is necessary to navigate using static methods
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    NotificationUtil.initializeNotificationsEventListeners();
    NotificationUtil.initializeIsolateReceivePort();
    WidgetsBinding.instance.addObserver(this);
  }

  void _deinit() {
    debugPrint("App > _deinit");
    ServiceManager.instance().deinit();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint("App > lifecycle changed $state");
    if (state == AppLifecycleState.detached) {
      _deinit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ListenableProvider(create: (context) => ConnectivityProvider()),
          ChangeNotifierProvider(create: (context) => AuthenticationProvider()),
          ChangeNotifierProvider(create: (context) => MemoryProvider()),
          ListenableProvider(create: (context) => PluginProvider()),
          ChangeNotifierProxyProvider<PluginProvider, MessageProvider>(
            create: (context) => MessageProvider(),
            update: (BuildContext context, value, MessageProvider? previous) =>
                (previous?..updatePluginProvider(value)) ?? MessageProvider(),
          ),
          ChangeNotifierProxyProvider2<MemoryProvider, MessageProvider,
              CaptureProvider>(
            create: (context) => CaptureProvider(),
            update: (BuildContext context, memory, message,
                    CaptureProvider? previous) =>
                (previous?..updateProviderInstances(memory, message)) ??
                CaptureProvider(),
          ),
          ChangeNotifierProxyProvider<CaptureProvider, DeviceProvider>(
            create: (context) => DeviceProvider(),
            update: (BuildContext context, captureProvider,
                    DeviceProvider? previous) =>
                (previous?..setProviders(captureProvider)) ?? DeviceProvider(),
          ),
          ChangeNotifierProxyProvider<DeviceProvider, OnboardingProvider>(
            create: (context) => OnboardingProvider(),
            update: (BuildContext context, value,
                    OnboardingProvider? previous) =>
                (previous?..setDeviceProvider(value)) ?? OnboardingProvider(),
          ),
          ListenableProvider(create: (context) => HomeProvider()),
          ChangeNotifierProxyProvider<DeviceProvider, SpeechProfileProvider>(
            create: (context) => SpeechProfileProvider(),
            update: (BuildContext context, device,
                    SpeechProfileProvider? previous) =>
                (previous?..setProviders(device)) ?? SpeechProfileProvider(),
          ),
          ChangeNotifierProxyProvider2<PluginProvider, MemoryProvider,
              MemoryDetailProvider>(
            create: (context) => MemoryDetailProvider(),
            update: (BuildContext context, plugin, memory,
                    MemoryDetailProvider? previous) =>
                (previous?..setProviders(plugin, memory)) ??
                MemoryDetailProvider(),
          ),
          ChangeNotifierProvider(create: (context) => CalenderProvider()),
          ChangeNotifierProvider(create: (context) => DiaryProvider()),
        ],
        builder: (context, child) {
          return WithForegroundTask(
            child: MaterialApp(
              navigatorObservers: [
                if (Env.instabugApiKey != null) InstabugNavigatorObserver(),
              ],
              debugShowCheckedModeBanner: F.env == Environment.dev,

              title: F.title,
              navigatorKey: MyApp.navigatorKey,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              // locale: const Locale('en'),
              theme: ThemeData(
                  useMaterial3: false,
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.black,
                    secondary: Colors.deepPurple,
                    surface: Colors.black38,
                  ),
                  snackBarTheme: SnackBarThemeData(
                    backgroundColor: Colors.grey.shade900,
                    contentTextStyle: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                  textTheme: TextTheme(
                    titleLarge:
                        const TextStyle(fontSize: 18, color: Colors.white),
                    titleMedium:
                        const TextStyle(fontSize: 16, color: Colors.white),
                    bodyMedium:
                        const TextStyle(fontSize: 14, color: Colors.white),
                    labelMedium:
                        TextStyle(fontSize: 12, color: Colors.grey.shade200),
                  ),
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: Colors.white,
                    selectionColor: Colors.deepPurple,
                  )),
              themeMode: ThemeMode.dark,
              builder: (context, child) {
                FlutterError.onError = (FlutterErrorDetails details) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Logger.instance.talker
                        .handle(details.exception, details.stack);
                  });
                };
                ErrorWidget.builder = (errorDetails) {
                  return CustomErrorWidget(
                      errorMessage: errorDetails.exceptionAsString());
                };
                return child!;
              },
              home: TalkerWrapper(
                talker: Logger.instance.talker,
                options: TalkerWrapperOptions(
                  enableErrorAlerts: true,
                  enableExceptionAlerts: true,
                  errorAlertBuilder: (context, data) {
                    return LoggerSnackbar(error: data);
                  },
                  exceptionAlertBuilder: (context, data) {
                    return LoggerSnackbar(exception: data);
                  },
                ),
                child: const DeciderWidget(),
              ),
            ),
          );
        });
  }
}

class DeciderWidget extends StatefulWidget {
  const DeciderWidget({super.key});

  @override
  State<DeciderWidget> createState() => _DeciderWidgetState();
}

class _DeciderWidgetState extends State<DeciderWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (context.read<ConnectivityProvider>().isConnected) {
        NotificationService.instance.saveNotificationToken();
      }
      if (context.read<AuthenticationProvider>().user != null) {
        context.read<HomeProvider>().setupHasSpeakerProfile();
        await Intercom.instance.loginIdentifiedUser(
          userId: AuthClient.currentUser?.id,
        );

        context.read<MessageProvider>().setMessagesFromCache();
        context.read<PluginProvider>().setPluginsFromCache();
        context.read<MessageProvider>().refreshMessages();
      } else {
        await Intercom.instance.loginUnidentifiedUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        if (SharedPreferencesUtil().onboardingCompleted &&
            authProvider.isSignedIn()) {
          return const HomePageWrapper();
        } else {
          return const OnboardingWrapper();
        }
      },
    );
  }
}

class CustomErrorWidget extends StatelessWidget {
  final String errorMessage;

  CustomErrorWidget({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 50.0,
            ),
            const SizedBox(height: 10.0),
            const Text(
              'Something went wrong! Please try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 63, 63, 63),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                errorMessage,
                textAlign: TextAlign.start,
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
            const SizedBox(height: 10.0),
            SizedBox(
              width: 210,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: errorMessage));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error message copied to clipboard'),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Copy error message'),
                    SizedBox(width: 10),
                    Icon(Icons.copy_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
