import 'package:flutter/material.dart';
import 'package:frysquiz/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Database.initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
