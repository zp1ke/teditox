import 'package:flutter/material.dart';
import 'package:teditox/src/app/app.dart';
import 'package:teditox/src/core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const TeditoxApp());
}
