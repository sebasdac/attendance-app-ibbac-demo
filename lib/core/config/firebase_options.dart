import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Firebase.initializeApp.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
     apiKey: 'DEMO_FIREBASE_KEY',
      appId: 'DEMO_APP_ID',
      messagingSenderId: 'DEMO_SENDER_ID',
      projectId: 'ibbac-attendance-demo',
      authDomain: 'ibbac-attendance-demo.firebaseapp.com',
      storageBucket: 'ibbac-attendance-demo.firebasestorage.app',
      );

  static const FirebaseOptions android = FirebaseOptions(
   apiKey: 'DEMO_FIREBASE_KEY',
    appId: 'DEMO_APP_ID',
    messagingSenderId: 'DEMO_SENDER_ID',
    projectId: 'ibbac-attendance-demo',
    authDomain: 'ibbac-attendance-demo.firebaseapp.com',
    storageBucket: 'ibbac-attendance-demo.firebasestorage.app',
  );
}
