import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'config/dependency_injection.dart';
import 'core/services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent unexpected async errors during startup from killing the app
  // (which otherwise can look like it's stuck on the Flutter logo).
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error (non-fatal): $error\n$stack');
    return true;
  };

  runZonedGuarded(() async {

  const isReleaseMode = bool.fromEnvironment('dart.vm.product');
  const useFirebaseEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: !isReleaseMode,
  );
  const firebaseEmulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  // Note: This project currently contains placeholder values in `firebase_options.dart`.
  // When Firebase isn't configured, initializing it can crash the app at runtime
  // (e.g., missing/invalid google_app_id for Crashlytics/Analytics).
  var firebaseInitialized = false;
  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  final hasRealFirebaseConfig =
      firebaseOptions.apiKey.isNotEmpty &&
      firebaseOptions.appId.isNotEmpty &&
      firebaseOptions.messagingSenderId.isNotEmpty &&
      !firebaseOptions.apiKey.startsWith('dummy-') &&
      !firebaseOptions.appId.startsWith('dummy-') &&
      !firebaseOptions.messagingSenderId.startsWith('dummy-');

  try {
    if (hasRealFirebaseConfig) {
      await Firebase.initializeApp(options: firebaseOptions);
      firebaseInitialized = true;

      if (useFirebaseEmulators) {
        FirebaseAuth.instance.useAuthEmulator(firebaseEmulatorHost, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(  
          firebaseEmulatorHost,
          8080,
        );
        FirebaseStorage.instance.useStorageEmulator(firebaseEmulatorHost, 9199);
        debugPrint(
          'Using Firebase Emulators at $firebaseEmulatorHost '
          '(auth:9099, firestore:8080, storage:9199)',
        );
      }
    } else {
      debugPrint(
        'Firebase is not configured (placeholder values detected). '
        'Running without Firebase.',
      );
    }
  } catch (error, stackTrace) {
    debugPrint(
      'Firebase initialization failed. Running without Firebase.\n'
      'Error: $error\n$stackTrace',
    );
  }

  // Initialize Crashlytics (only when Firebase is configured)
  if (firebaseInitialized) {
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Setup dependency injection
  await configureDependencies();

  // Initialize notifications
  if (firebaseInitialized) {
    try {
      await getIt<NotificationService>().initialize();
    } catch (error, stackTrace) {
      debugPrint(
        'Notification initialization failed (non-fatal).\n'
        'Error: $error\n$stackTrace',
      );
    }
  }

  // Custom BLoC observer for debugging
  Bloc.observer = AppBlocObserver();

    runApp(DiasporaDeliveryApp(firebaseInitialized: firebaseInitialized));
  }, (error, stackTrace) {
    debugPrint('Uncaught zone error (non-fatal): $error\n$stackTrace');
  });
}

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('${bloc.runtimeType} $error $stackTrace');
    try {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    } catch (_) {
      // Firebase may be unconfigured; ignore.
    }
  }
}
