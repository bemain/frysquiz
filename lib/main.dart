import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frysquiz/providers/auth_provider.dart';

import 'app.dart';
import 'data/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Database.initialize();

  final container = ProviderContainer();
  await container.read(authNotifierProvider).restoreSession();

  runApp(UncontrolledProviderScope(container: container, child: FrysquizApp()));
}
