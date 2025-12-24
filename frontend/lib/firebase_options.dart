// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: 'dummy-app-id',
    messagingSenderId: 'dummy-sender-id',
    projectId: 'diaspora-delivery',
    authDomain: 'diaspora-delivery.firebaseapp.com',
    storageBucket: 'diaspora-delivery.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBaOv9R-4Til8A4HSx8MdTvCM7j6XNg0d8',
    appId: '1:961123527612:android:76041ad1c64e1aad3e99b9',
    messagingSenderId: '961123527612',
    projectId: 'mbapp-dev-2025-noor',
    storageBucket: 'mbapp-dev-2025-noor.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: 'dummy-app-id',
    messagingSenderId: 'dummy-sender-id',
    projectId: 'diaspora-delivery',
    storageBucket: 'diaspora-delivery.appspot.com',
    iosClientId: 'dummy-ios-client-id',
    iosBundleId: 'com.example.diasporaDelivery',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: 'dummy-app-id',
    messagingSenderId: 'dummy-sender-id',
    projectId: 'diaspora-delivery',
    storageBucket: 'diaspora-delivery.appspot.com',
    iosClientId: 'dummy-ios-client-id',
    iosBundleId: 'com.example.diasporaDelivery',
  );
}