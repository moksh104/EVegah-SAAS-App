import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EVagah Employee',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
