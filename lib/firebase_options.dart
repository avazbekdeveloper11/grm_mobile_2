import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCAXYgw3PK5cYYfschz7IHaUmzpW4mdklM',
    appId: '1:266892889801:android:b69368f17f7744cbc6c718',
    messagingSenderId: '266892889801',
    projectId: 'grm-mobile',
    storageBucket: 'grm-mobile.firebasestorage.app',
  );
}
