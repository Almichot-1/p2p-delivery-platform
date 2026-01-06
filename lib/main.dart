import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const diagTag = '###FIREBASE_DIAG###';

  try {
    await Firebase.initializeApp();
    final options = Firebase.app().options;
    final message =
        '$diagTag Firebase initialized: projectId=${options.projectId}, appId=${options.appId}';
    // `print` tends to show up reliably in `flutter run` logs.
    // `developer.log` also shows up in logcat as structured logs.
    print(message);
    debugPrint(message);
    developer.log(message, name: 'diaspora_delivery');
  } catch (e) {
    // Allow app to boot before native Firebase config is added.
    final message =
        '$diagTag Firebase.initializeApp() failed (likely missing config): $e';
    print(message);
    debugPrint(message);
    developer.log(message, name: 'diaspora_delivery');
  }
  configureDependencies();

  runApp(const DiasporaApp());

  Future<void>.delayed(const Duration(seconds: 2), () {
    final apps = Firebase.apps;
    final options = apps.isEmpty ? null : Firebase.app().options;
    final message = apps.isEmpty
        ? '$diagTag Firebase delayed: no Firebase apps initialized'
        : '$diagTag Firebase delayed: apps=${apps.length}, projectId=${options!.projectId}, appId=${options.appId}';
    print(message);
    debugPrint(message);
    developer.log(message, name: 'diaspora_delivery');
  });

  // Log again after the first frame, to ensure the message is visible
  // even if early prints occur before the tool attaches.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final apps = Firebase.apps;
    if (apps.isEmpty) {
      const message = '$diagTag Firebase postframe: no Firebase apps initialized';
      print(message);
      debugPrint(message);
      developer.log(message, name: 'diaspora_delivery');
      return;
    }

    final options = Firebase.app().options;
    final message =
        '$diagTag Firebase postframe: apps=${apps.length}, projectId=${options.projectId}, appId=${options.appId}';
    print(message);
    debugPrint(message);
    developer.log(message, name: 'diaspora_delivery');
  });
}
