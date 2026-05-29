import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_offline_ai_doc_chat/app/di/service_locator.dart';
import 'package:flutter_offline_ai_doc_chat/app/router/app_router.dart';
import 'package:flutter_offline_ai_doc_chat/app/theme/app_theme.dart';
import 'package:flutter_offline_ai_doc_chat/core/database/local_database.dart';
import 'package:flutter_offline_ai_doc_chat/core/storage/app_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  await LocalDatabase.initialize();
  await AppPreferences.initialize();
  await setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Offline AI Doc Chat',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
