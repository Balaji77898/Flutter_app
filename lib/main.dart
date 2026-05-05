import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_unified_app/core/auth_provider.dart';
import 'core/theme.dart';
import 'router.dart';

// Admin Providers
import 'admin/core/providers/restaurant_provider.dart';

// Staff Providers
import 'staff/contexts/orders_provider.dart';
import 'staff/contexts/tables_provider.dart';
import 'staff/contexts/menu_provider.dart';
import 'staff/contexts/auth_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    final authProvider = AuthProvider();
    final staffAuthProvider = StaffAuthProvider();

    // Start loading but don't block forever if one fails
    await Future.wait([
      authProvider.loadAuth().timeout(const Duration(seconds: 5), onTimeout: () {}),
      staffAuthProvider.loadAuth().timeout(const Duration(seconds: 5), onTimeout: () {}),
    ]).catchError((e) => debugPrint("Initialization error: $e"));

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: staffAuthProvider),
          ChangeNotifierProvider(create: (_) => RestaurantProvider()),
          ChangeNotifierProvider(create: (_) => OrdersProvider()),
          ChangeNotifierProvider(create: (_) => TablesProvider()),
          ChangeNotifierProvider(create: (_) => MenuProvider()),
        ],
        child: const RestaurantUnifiedApp(),
      ),
    );
  } catch (e) {
    debugPrint("CRITICAL MAIN ERROR: $e");
    // Still try to run the app
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text("App initialization failed. Please refresh.")))));
  }
}

class RestaurantUnifiedApp extends StatefulWidget {
  const RestaurantUnifiedApp({super.key});

  @override
  State<RestaurantUnifiedApp> createState() => _RestaurantUnifiedAppState();
}

class _RestaurantUnifiedAppState extends State<RestaurantUnifiedApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
