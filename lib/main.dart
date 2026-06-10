// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/fcm_service_flutter.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'l10n/strings.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/worker/worker_home.dart';
import 'screens/driver/driver_home.dart';
import 'screens/upakovchik/upakovchik_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('uz', null);
  await initializeDateFormatting('en', null);

  // Firebase init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final api = await ApiService.getInstance();
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  final orderProvider = OrderProvider(api);
  final userProvider = UserProvider(api);

  // Til o'zgarganda ApiService, OrderProvider va UserProvider ni yangilash
  api.setLanguage(
    themeProvider.language == AppLanguage.uzCyrillic ? 'cyrillic' : 'latin',
  );
  themeProvider.addListener(() {
    api.setLanguage(
      themeProvider.language == AppLanguage.uzCyrillic ? 'cyrillic' : 'latin',
    );
    orderProvider.loadOrders();
    userProvider.loadUsers();
  });

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: orderProvider),
        ChangeNotifierProxyProvider<OrderProvider, AuthProvider>(
          create: (_) => AuthProvider(api),
          update: (_, orderProvider, auth) {
            auth!.setOrderProvider(orderProvider);
            return auth;
          },
        ),
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: const GilamApp(),
    ),
  );
}

class GilamApp extends StatelessWidget {
  const GilamApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Gilam Yuvish',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      builder: (context, child) {
        final scale = context.watch<ThemeProvider>().fontScale;
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: child!,
          ),
        );
      },
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();

    // 401 — sessiya tugagan, qayta login
    api.onUnauthorized = () {
      if (!mounted) return;
      auth.logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    };

    // 426 — ilova versiyasi eskirgan
    api.onOutdated = (msg) {
      if (!mounted) return;
      final s = S(context.read<ThemeProvider>().language);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(Icons.system_update, color: Colors.orange, size: 48),
          title: Text(s.updateRequired, textAlign: TextAlign.center),
          content: Text(msg, textAlign: TextAlign.center),
          actions: [FilledButton(onPressed: () {}, child: const Text('OK'))],
        ),
      );
    };

    await auth.init();
    if (auth.isLoggedIn) {
      await Future.wait([
        context.read<OrderProvider>().loadOrders(),
        context.read<UserProvider>().loadUsers(),
      ]);
      await FcmService.init(api);
    }
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!_initialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  size: 44,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Gilam Yuvish',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Boshqaruv tizimi',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const LoginScreen();

    switch (auth.currentUser!.role) {
      case UserRole.admin:
        return const AdminHome();
      case UserRole.worker:
        return const WorkerHome();
      case UserRole.driver:
        return const DriverHome();
      case UserRole.upakovchik:
        return const UpakovchikHome();
    }
  }
}
