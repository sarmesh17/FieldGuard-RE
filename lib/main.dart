import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/router/app_router.dart';
import 'package:field_guard_re/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FieldGuard Agent',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
