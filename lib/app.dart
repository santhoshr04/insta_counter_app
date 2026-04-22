import 'package:flutter/material.dart';
import 'package:insta_counter_app/core/constants/app_constants.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';
import 'package:insta_counter_app/features/splash/splash_screen.dart';
import 'package:insta_counter_app/providers/counter_notifier.dart';
import 'package:insta_counter_app/providers/shell_tab_notifier.dart';
import 'package:insta_counter_app/providers/theme_variant_notifier.dart';
import 'package:provider/provider.dart';

class InstaCounterApp extends StatelessWidget {
  const InstaCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CounterNotifier()),
        ChangeNotifierProvider(create: (_) => ShellTabNotifier()),
        ChangeNotifierProvider(create: (_) => ThemeVariantNotifier()),
      ],
      child: Consumer<ThemeVariantNotifier>(
        builder: (context, theme, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: theme.useGraphite
                ? AppTheme.darkGraphite()
                : AppTheme.darkPremium(),
            home: child,
          );
        },
        child: const SplashScreen(),
      ),
    );
  }
}
