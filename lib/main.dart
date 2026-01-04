import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/ddns_service.dart';
import 'services/background_service.dart';
import 'package:ddns_updater/core/theme/app_theme.dart';
import 'package:ddns_updater/providers/config_provider.dart';
import 'package:ddns_updater/providers/home_provider.dart';
import 'package:ddns_updater/ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize BackgroundService early to ensure the isolate is ready
  await BackgroundService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DDNSService()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = ConfigProvider();
            provider.loadConfigs();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: MaterialApp(
        title: 'DDNS Updater',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
