import 'package:flutter/material.dart';
import 'package:lambda_finder/Screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lambda Finder',
      theme: ThemeData.light(),
      darkTheme: ThemeData.light(),
      home: const MainScreen(),
    );
  }
}
