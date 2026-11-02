import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// STEP: paste your own Firebase values below (see README.md, Part A).
/// Firebase console -> Project settings (gear icon) -> Your apps.
class AppConfig {
  // ---- WEB app values (used when running in Chrome / web link) ----
  static const _web = FirebaseOptions(
    apiKey: 'AIzaSyD7PoCo36hbGZVIXu2zpFDGr73bPctxkBs',
    appId: '1:197099349143:web:bf84398483f638cf8375d2',
    messagingSenderId: '197099349143',
    projectId: 'kare-help-desk',
    authDomain: 'kare-help-desk.firebaseapp.com',
    storageBucket: 'kare-help-desk.firebasestorage.app',
  );

  // ---- ANDROID app values (used in the Android app / APK) ----
  // Package name to register in Firebase: com.kare.kare_helpdesk
  static const _android = FirebaseOptions(
    apiKey: 'AIzaSyDnBjpLq-3BHNr_ZlPpVyUpfb8JNt2ZK1s',
    appId: '1:197099349143:android:68c1990bf45ad6918375d2',
    messagingSenderId: '197099349143',
    projectId: 'kare-help-desk',
    storageBucket: 'kare-help-desk.firebasestorage.app',
  );

  static FirebaseOptions get firebaseOptions => kIsWeb ? _web : _android;

  /// Students log in with a register number, but Firebase Auth needs an
  /// email, so we map the register number to a private pseudo-email.
  static const emailDomain = 'students.kare.app';
  static String emailFromRegNo(String regNo) =>
      '${regNo.trim().toLowerCase()}@$emailDomain';
}
