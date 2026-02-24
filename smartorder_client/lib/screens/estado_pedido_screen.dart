import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EstadoPedidoScreen extends StatelessWidget {
  final String pedidoId;

  const EstadoPedidoScreen({Key? key, required this.pedidoId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estado del Pedido'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .doc(pedidoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el pedido'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final estado = data['estado'] ?? 'pendiente';
          final total = (data['total'] ?? 0).toDouble();
          final items = (data['items'] as List<dynamic>?) ?? [];

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 20),
                _buildIconoEstado(estado),
                SizedBox(height: 20),
                Text(
                  _textoEstado(estado),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  _subtextoEstado(estado),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),

                // Timeline de estados
                _buildTimeline(estado),

                SizedBox(height: 30),

                // Resumen del pedido
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumen del Pedido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      ...items.map((item) {
                        final nombre = item['nombre'] ?? '';
                        final cantidad = item['cantidad'] ?? 1;
                        final precio = (item['precio_snapshot'] ?? 0).toDouble();
                        final mods = (item['modificadores_aplicados'] as List<dynamic>?) ?? [];
                        final modsTexto = mods.map((m) => m['nombre']).join(', ');
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${cantidad}x ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                                    if (modsTexto.isNotEmpty)
                                      Text(modsTexto, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              Text('\$${(precio * cantidad).toStringAsFixed(2)}'),
                            ],
                          ),
                        );
                      }).toList(),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Pedido #${pedidoId.substring(0, 6).toUpperCase()}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconoEstado(String estado) {
    IconData icono;
    Color color;
    double size = 80;

    switch (estado) {
      case 'pendiente':
        icono = Icons.hourglass_top;
        color = Colors.orange;
        break;
      case 'en_preparacion':
        icono = Icons.restaurant;
        color = Colors.blue;
        break;
      case 'listo':
        icono = Icons.check_circle;
        color = Colors.green;
        break;
      case 'pagado':
        icono = Icons.paid;
        color = Colors.purple;
        break;
      default:
        icono = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icono, size: size, color: color),
    );
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pedido Recibido';
      case 'en_preparacion': return 'En Preparacion';
      case 'listo': return 'Pedido Listo!';
      case 'pagado': return 'Pagado';
      default: return estado;
    }
  }

  String _subtextoEstado(String estado) {
    switch (estado) {
      case 'pendiente': return 'Tu pedido ha sido recibido y sera procesado pronto';
      case 'en_preparacion': return 'Nuestro equipo esta preparando tu pedido';
      case 'listo': return 'Tu pedido esta listo para recoger!';
      case 'pagado': return 'Gracias por tu compra!';
      default: return '';
    }
  }

  Widget _buildTimeline(String estadoActual) {
    final estados = ['pendiente', 'en_preparacion', 'listo', 'pagado'];
    final etiquetas = ['Recibido', 'Preparando', 'Listo', 'Pagado'];
    final iconos = [Icons.receipt_long, Icons.restaurant, Icons.check_circle, Icons.paid];
    final indexActual = estados.indexOf(estadoActual);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(estados.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Linea conectora
          final stepIndex = i ~/ 2;
          final activo = stepIndex < indexActual;
          return Expanded(
            child: Container(
              height: 3,
              color: activo ? Colors.green : Colors.grey[300],
            ),
          );
        } else {
          // Circulo de estado
          final stepIndex = i ~/ 2;
          final completado = stepIndex < indexActual;
          final actual = stepIndex == indexActual;
          final color = completado ? Colors.green : (actual ? Colors.deepOrange : Colors.grey[300]!);

          return Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: completado || actual ? color : Colors.grey[100],
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  iconos[stepIndex],
                  size: 18,
                  color: completado || actual ? Colors.white : Colors.grey[400],
                ),
              ),
              SizedBox(height: 4),
              Text(
                etiquetas[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: actual ? FontWeight.bold : FontWeight.normal,
                  color: completado || actual ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
