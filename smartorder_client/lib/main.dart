import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/carrito_provider.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/menu_digital_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // En web, leer el mesa ID directamente de la URL del navegador
  String? mesaIdFromUrl;
  if (kIsWeb) {
    final uri = Uri.base;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[0] == 'mesa') {
      mesaIdFromUrl = segments[1];
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
      ],
      child: MyApp(mesaIdFromUrl: mesaIdFromUrl),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? mesaIdFromUrl;

  const MyApp({Key? key, this.mesaIdFromUrl}) : super(key: key);

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
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    // Si hay mesa en la URL (viene del QR web), asignar directo
    if (mesaIdFromUrl != null) {
      return _MesaLoaderScreen(mesaId: mesaIdFromUrl!);
    }
    // En web sin mesa -> pantalla de bienvenida
    if (kIsWeb) {
      return _WebBienvenidaScreen();
    }
    // En movil -> QR scanner
    return QrScannerScreen();
  }
}

/// Pantalla intermedia que asigna la mesa y navega al menu
class _MesaLoaderScreen extends StatefulWidget {
  final String mesaId;
  const _MesaLoaderScreen({required this.mesaId});

  @override
  State<_MesaLoaderScreen> createState() => _MesaLoaderScreenState();
}

class _MesaLoaderScreenState extends State<_MesaLoaderScreen> {
  bool _error = false;
  String _mensajeError = '';

  @override
  void initState() {
    super.initState();
    _asignarMesa();
  }

  Future<void> _asignarMesa() async {
    try {
      await context.read<CarritoProvider>().asignarMesa(widget.mesaId);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MenuDigitalScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _mensajeError = 'No se pudo asignar la mesa: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange,
      body: Center(
        child: _error
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 60),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      _mensajeError,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () {
                      setState(() => _error = false);
                      _asignarMesa();
                    },
                    child: Text('Reintentar', style: TextStyle(color: Colors.deepOrange)),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Asignando mesa ${widget.mesaId}...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Pantalla de bienvenida para web cuando no hay mesa en la URL
class _WebBienvenidaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2, size: 80, color: Colors.deepOrange),
              SizedBox(height: 20),
              Text(
                'SmartOrder Sync',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Escanea el codigo QR de tu mesa para comenzar a ordenar',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Icon(Icons.phone_android, size: 40, color: Colors.grey[400]),
              SizedBox(height: 8),
              Text(
                'Usa la camara de tu celular para escanear el QR',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
