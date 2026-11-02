import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() => runApp(const RevaApp());

class RevaApp extends StatelessWidget {
  const RevaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'REVA',
        theme: revaTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      );
}
