import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/dev/role_switcher.dart';

void main() {
  runApp(const FundixApp());
}

class FundixApp extends StatelessWidget {
  const FundixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fundix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const RoleSwitcherScreen(),
    );
  }
}
