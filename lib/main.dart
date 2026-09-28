import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/navigation_data.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: const AiraApp(),
    ),
  );
}

class AiraApp extends StatelessWidget {
  const AiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NavigationProvider>(context);

    return MaterialApp(
      title: 'Aira',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
