import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCLwWfXuE6557M0P-Qz85oA9YB-VhT4_pg',
    appId: '1:1096747550797:web:e02a8ba9b3447f17ecf404',
    messagingSenderId: '1096747550797',
    projectId: 'medicare-plus-38bf0',
    authDomain: 'medicare-plus-38bf0.firebaseapp.com',
    storageBucket: 'medicare-plus-38bf0.firebasestorage.app',
    measurementId: 'G-8XFKEK1JL0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-PLRjbLTAmY0_bJYM6s-Gb2CJinIoKV4',
    appId: '1:1096747550797:android:145a21907cda7761ecf404',
    messagingSenderId: '1096747550797',
    projectId: 'medicare-plus-38bf0',
    storageBucket: 'medicare-plus-38bf0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBFmY1hWY-cHE7dnqMZq9MRE0VBDYN9ToY',
    appId: '1:1096747550797:ios:ee142cd4aedc3970ecf404',
    messagingSenderId: '1096747550797',
    projectId: 'medicare-plus-38bf0',
    storageBucket: 'medicare-plus-38bf0.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBFmY1hWY-cHE7dnqMZq9MRE0VBDYN9ToY',
    appId: '1:1096747550797:ios:ee142cd4aedc3970ecf404',
    messagingSenderId: '1096747550797',
    projectId: 'medicare-plus-38bf0',
    storageBucket: 'medicare-plus-38bf0.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCLwWfXuE6557M0P-Qz85oA9YB-VhT4_pg',
    appId: '1:1096747550797:web:ab317ab4eecc8278ecf404',
    messagingSenderId: '1096747550797',
    projectId: 'medicare-plus-38bf0',
    authDomain: 'medicare-plus-38bf0.firebaseapp.com',
    storageBucket: 'medicare-plus-38bf0.firebasestorage.app',
    measurementId: 'G-N1QSYE2VBE',
  );
}
