import 'package:flutter/material.dart';
import 'config/router_config.dart';
import 'config/theme_config.dart';
import 'core/constants/strings.dart';

class StillFeedApp extends StatelessWidget {
  const StillFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}