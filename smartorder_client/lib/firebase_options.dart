import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Forzamos el uso de las credenciales Web en Android para prototipar
    // ya que no hemos configurado el google-services.json nativo
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCsp1fZE2qFHhgBi_Fb8wXkXvk5ij-JPebY',
    appId: '1:984530456813:web:d5c8d0b701373639bb3ce4',
    messagingSenderId: '984530456813',
    projectId: 'cafeteria-eecdf',
    authDomain: 'cafeteria-eecdf.firebaseapp.com',
    storageBucket: 'cafeteria-eecdf.firebasestorage.app',
    measurementId: 'G-SJTnTE2BB1',
  );
}
