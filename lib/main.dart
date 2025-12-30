import 'package:flutter/material.dart';
import 'package:tns_kiosk/pages/root_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TNSKiosk());
}

// Ultraroot Application
class TNSKiosk extends StatelessWidget {
  const TNSKiosk({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeMode themeMode = ThemeMode.system;

    return MaterialApp(
      themeMode: themeMode,
      title: 'TNS Mobile Application',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade700,
          primary: Colors.blue.shade700,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade300,
          primary: Colors.blue.shade300,
          brightness: Brightness.dark,
        ),
      ),
      home: RootPage(),
    );
  }
}
