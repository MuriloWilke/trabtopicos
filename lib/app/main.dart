import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:trabtopicos/app/screens/image_picker_screen.dart';

import 'app_module.dart';

const Color primaryBlue = Color(0xFF1976D2);
const Color primaryDarkBlue = Color(0xFF0D47A1);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeCameras();

  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Inventário Inteligente',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryBlue,
            primary: primaryBlue,
            secondary: primaryDarkBlue,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: primaryDarkBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
          )
      ),
      routerDelegate: Modular.routerDelegate,
      routeInformationParser: Modular.routeInformationParser,
    );
  }
}