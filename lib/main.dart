// main.dart
import 'package:flutter/material.dart';
// Only ProviderScope is needed from Riverpod in main.dart.
// Hide everything else that conflicts with the provider package.
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide Consumer, ChangeNotifierProvider, Provider;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:q_kics/providers/booking_provider.dart';
import 'package:q_kics/providers/chat_provider.dart';
import 'package:q_kics/providers/notification_provider.dart';
import 'package:q_kics/services/notification_service.dart';
import 'package:q_kics/services/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/providers/company_provider.dart';
import 'package:q_kics/providers/navigation_provider.dart';
import 'package:q_kics/providers/profile_provider.dart';
import 'package:q_kics/providers/expert_profile_provider.dart';
import 'package:q_kics/providers/entrepreneur_profile_provider.dart';

import 'package:q_kics/profile/services/profile_api_service.dart';
import 'package:q_kics/profile/services/expert_api_service.dart';
import 'package:q_kics/profile/services/entrepreneur_api_service.dart';
import 'package:q_kics/profile/services/investor_api_service.dart';
import 'package:q_kics/providers/authorized_profiles_provider.dart';
import 'package:q_kics/subscriptions/services/subscription_service.dart';
import 'package:q_kics/subscriptions/providers/subscription_provider.dart';

import 'package:q_kics/Auth/login.dart';
import 'package:q_kics/main_navigation.dart';
import 'package:q_kics/providers/document_provider.dart';
import 'package:q_kics/documents/services/document_api_service.dart';
import 'package:q_kics/providers/theme_provider.dart';
import 'package:q_kics/screens/splash_screen.dart';

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    if (kDebugMode) print('Firebase initialized successfully');
  } catch (e) {
    if (kDebugMode) print('Firebase initialization error: $e');
  }

  // Initialize Push Notification Service
  try {
    await PushNotificationService.instance.initialize();
  } catch (e) {
    if (kDebugMode) print('PushNotificationService initialization error: $e');
  }

  // Optimized for social media feed (holds ~100-150 images in memory)
  PaintingBinding.instance.imageCache.maximumSize = 100 * 1024 * 1024; // 100 MB
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;

  final apiProvider = ApiProvider();
  await apiProvider.init();

  runApp(
    // ProviderScope is the Riverpod root — required once at the top level.
    // The rest of the app continues using the `provider` package unchanged.
    ProviderScope(
      child: MultiProvider(
      providers: [
        // ================= CORE API =================
        ChangeNotifierProvider<ApiProvider>.value(value: apiProvider),
        ChangeNotifierProvider(
          create: (context) => CompanyProvider(
            apiProvider: context.read<ApiProvider>(),
          )..fetchMyCompanies()..fetchCompanyList(), // Pre-fetch basic layout lists
        ),

        // ================= USER PROFILE =================
        ChangeNotifierProvider(
          create: (context) => ProfileProvider(
            ProfileApiService(context.read<ApiProvider>().dio),
            context.read<ApiProvider>(), // ✅ REQUIRED
          )..loadProfile(),
        ),
        // ================= EXPERT PROFILE =================
        ChangeNotifierProvider(
          create: (context) => ExpertProfileProvider(
            ExpertApiService(context.read<ApiProvider>().dio),
          )..fetchExpertProfile(),
        ),

        // ================= ENTREPRENEUR PROFILE =================
        ChangeNotifierProvider(
          create: (context) => EntrepreneurProfileProvider(
            EntrepreneurApiService(context.read<ApiProvider>().dio),
          )..loadProfile(),
        ),

        // ================= ENTREPRENEUR PROFILE =================
        ChangeNotifierProvider(create: (_) => NavigationProvider()),

        // ================= BOOKING PROVIDER =================

        // ================= AUTHORIZED PROFILES =================
        ChangeNotifierProvider(
          create: (context) => AuthorizedProfilesProvider(
            expertApi: ExpertApiService(context.read<ApiProvider>().dio),
            entrepreneurApi: EntrepreneurApiService(
              context.read<ApiProvider>().dio,
            ),
            investorApi: InvestorApiService(context.read<ApiProvider>().dio),
          )..fetchAll(),
        ),

        ChangeNotifierProvider(
          create: (context) => SubscriptionProvider(
            SubscriptionService(context.read<ApiProvider>().dio),
          )..fetchActiveSubscription(),
        ),

        ChangeNotifierProvider(
          create: (context) => DocumentProvider(
            DocumentApiService(context.read<ApiProvider>().dio),
          )..fetchDocuments(),
        ),

        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(NotificationService()),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryRed = Color(0xFFE31E24);
  static const Color accentRed = Color(0xFFFF3B30);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: globalNavigatorKey,
      title: 'Q-KICS',
      themeMode: themeProvider.themeMode,

      // ================= LIGHT THEME =================
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: GoogleFonts.inter().fontFamily,

        colorScheme: const ColorScheme.light(
          primary: primaryRed,
          secondary: accentRed,
          tertiary: Color.fromARGB(255, 22, 104, 255),
          surface: Colors.white,
        ),

        scaffoldBackgroundColor: const Color(0xFFF5F5F5),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),

        cardTheme: const CardThemeData(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      ),

      // ================= DARK THEME =================
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.inter().fontFamily,

        colorScheme: const ColorScheme.dark(
          primary: primaryRed,
          secondary: accentRed,
          tertiary: Color.fromARGB(255, 22, 104, 255),
          surface: Color(0xFF1E1E1E),
        ),

        scaffoldBackgroundColor: const Color(0xFF121212),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),

        cardTheme: const CardThemeData(
          elevation: 6,
          color: Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(themeProvider.fontSizeFactor),
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}

// ================= AUTH WRAPPER =================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiProvider>(
      builder: (_, api, __) {
        return api.isAuthenticated ? const MainNavigation() : const LoginPage();
      },
    );
  }
}
