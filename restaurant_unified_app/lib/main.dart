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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authProvider = AuthProvider();
  await authProvider.loadAuth();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => TablesProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
      ],
      child: const RestaurantUnifiedApp(),
    ),
  );
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
      title: 'Restaurant Unified',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
