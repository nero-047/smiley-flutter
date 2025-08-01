import 'package:flutter/material.dart';
import 'package:smiley/pages/home.dart';
import 'package:smiley/services/notifications.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notification service
  NotificationService().initialize();

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}