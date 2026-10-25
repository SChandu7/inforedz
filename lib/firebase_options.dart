// Firebase config for the inforedzapp project (Android + iOS).
// Values mirror android/app/google-services.json and
// ios/Runner/GoogleService-Info.plist; regenerate with `flutterfire configure`.
// These identify the Firebase project and are not secret.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is only configured for Android and iOS.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAlOKac6eQfLISeMDSnhLOpDa0PRG48Jkk',
    appId: '1:883557673550:android:9a37a761e5d0ab4914b11f',
    messagingSenderId: '883557673550',
    projectId: 'inforedzapp',
    storageBucket: 'inforedzapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCxi6oTHSi78P6z1_F_rG4AriYZvuuqn4I',
    appId: '1:883557673550:ios:be87c882c01f8ef814b11f',
    messagingSenderId: '883557673550',
    projectId: 'inforedzapp',
    storageBucket: 'inforedzapp.firebasestorage.app',
    iosBundleId: 'com.inforedz.app',
  );
}
