import 'package:flutter/material.dart';
import 'package:flutter_infinite_scroll/home_page.dart';
import 'package:flutter_infinite_scroll/home_page2.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}
