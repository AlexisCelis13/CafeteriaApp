import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import 'menu_digital_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _procesando = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camara con scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay oscuro con ventana de escaneo
          _buildOverlay(),

          // Header
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
                      SizedBox(width: 12),
                      Text(
                        'SmartOrder Sync',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Escanea el codigo QR de tu mesa para comenzar a ordenar',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Indicador de procesamiento
          if (_procesando)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.deepOrange),
                    SizedBox(height: 16),
                    Text('Asignando mesa...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),

          // Boton para ingresar mesa manualmente (fallback)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: SafeArea(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _ingresarMesaManual,
                icon: Icon(Icons.edit, color: Colors.white),
                label: Text('Ingresar numero de mesa manualmente', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.65;
        final top = constraints.maxHeight * 0.35;
        final left = (constraints.maxWidth - scanAreaSize) / 2;

        return Stack(
          children: [
            // Zona de escaneo con borde animado
            Positioned(
              top: top,
              left: left,
              child: Container(
                width: scanAreaSize,
                height: scanAreaSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepOrange, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_procesando) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final qrData = barcode.rawValue!;
    
    // Esperamos que el QR contenga el ID de la mesa, ej: "mesa_01" o "MESA-5"
    // Extraemos el ID de mesa del QR
    String mesaId = qrData.trim();
    
    // Si el QR contiene una URL tipo "smartorder://mesa/mesa_01", extraer solo el ID
    if (mesaId.contains('/')) {
      mesaId = mesaId.split('/').last;
    }

    setState(() => _procesando = true);

    try {
      await context.read<CarritoProvider>().asignarMesa(mesaId);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MenuDigitalScreen()),
        );
      }
    } catch (e) {
      setState(() => _procesando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al asignar mesa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _ingresarMesaManual() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Numero de Mesa'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Ej: mesa_01',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () async {
              final mesaId = controller.text.trim();
              if (mesaId.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _procesando = true);
              try {
                await context.read<CarritoProvider>().asignarMesa(mesaId);
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => MenuDigitalScreen()),
                  );
                }
              } catch (e) {
                setState(() => _procesando = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
