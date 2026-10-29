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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDqxamVzzpyWI4b5BrhmbH0sUyf8r6W-_U',
    appId: '1:53125151176:web:91d59e1c8ffc628c1ca8fd',
    messagingSenderId: '53125151176',
    projectId: 'durga-puja-82fe4',
    authDomain: 'durga-puja-82fe4.firebaseapp.com',
    storageBucket: 'durga-puja-82fe4.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqxamVzzpyWI4b5BrhmbH0sUyf8r6W-_U',
    appId: '1:53125151176:android:91d59e1c8ffc628c1ca8fd',
    messagingSenderId: '53125151176',
    projectId: 'durga-puja-82fe4',
    storageBucket: 'durga-puja-82fe4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDqxamVzzpyWI4b5BrhmbH0sUyf8r6W-_U',
    appId: '1:53125151176:ios:91d59e1c8ffc628c1ca8fd',
    messagingSenderId: '53125151176',
    projectId: 'durga-puja-82fe4',
    storageBucket: 'durga-puja-82fe4.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDqxamVzzpyWI4b5BrhmbH0sUyf8r6W-_U',
    appId: '1:53125151176:ios:91d59e1c8ffc628c1ca8fd',
    messagingSenderId: '53125151176',
    projectId: 'durga-puja-82fe4',
    storageBucket: 'durga-puja-82fe4.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDqxamVzzpyWI4b5BrhmbH0sUyf8r6W-_U',
    appId: '1:53125151176:web:91d59e1c8ffc628c1ca8fd',
    messagingSenderId: '53125151176',
    projectId: 'durga-puja-82fe4',
    authDomain: 'durga-puja-82fe4.firebaseapp.com',
    storageBucket: 'durga-puja-82fe4.firebasestorage.app',
  );
}
