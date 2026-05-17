import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/auth_gate.dart';

void main() {
  runApp(const ProviderScope(child: FundixApp()));
}

class FundixApp extends ConsumerWidget {
  const FundixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final lang = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Fundix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: Locale(lang),
      home: const AuthGate(),
    );
  }
}
