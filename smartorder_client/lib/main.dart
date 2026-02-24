import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/carrito_provider.dart';
import 'screens/menu_digital_screen.dart';
import 'firebase_options.dart'; // Recuerda generar este archivo usando 'flutterfire configure'

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización de Firebase (Descomentar la línea de options si se usa FlutterFire CLI)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartOrder Sync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          color: Colors.deepOrange,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: MenuDigitalScreen(),
    );
  }
}
