// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const ProviderScope(child: _App()));
}

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Flovi Driver',
      theme: _buildTheme(),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2196F3),
        secondary: Color(0xFF64B5F6),
        surface: Color(0xFF1B2C3E),
        onSurface: Color(0xFFE0E8F0),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      cardColor: const Color(0xFF1B2C3E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B2C3E),
        foregroundColor: Color(0xFFE0E8F0),
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF0D1B2A),
      ),
    );
  }
}
