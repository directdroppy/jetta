import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/role_select_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: JColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const JettaApp());
}

class JettaApp extends StatelessWidget {
  const JettaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jetta',
      debugShowCheckedModeBanner: false,
      theme: buildJettaTheme(),
      home: const RoleSelectScreen(),
    );
  }
}
