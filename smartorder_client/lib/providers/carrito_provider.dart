import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_models.dart';

class CarritoProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ItemPedidoSnapshot> _items = [];
  String? _pedidoActivoId;
  String? _mesaId;
  
  List<ItemPedidoSnapshot> get items => _items;
  String? get pedidoActivoId => _pedidoActivoId;
  String? get mesaId => _mesaId;

  double get totalPedido => _items.fold(0, (sum, item) => sum + item.subtotalItem);

  /// Asigna la mesa escaneada y la marca como 'ocupada' en Firestore
  Future<void> asignarMesa(String mesaId) async {
    _mesaId = mesaId;
    notifyListeners();
    
    // Actualizar estado de la mesa en Firestore
    await _firestore.collection('mesas').doc(mesaId).update({
      'estado': 'ocupada',
    });
  }

  void agregarAlCarrito(ItemPedidoSnapshot item) {
    _items.add(item);
    notifyListeners();
  }

  void eliminarItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void actualizarCantidad(int index, int nuevaCantidad) {
    if (nuevaCantidad < 1) {
      eliminarItem(index);
      return;
    }
    _items[index] = ItemPedidoSnapshot(
      productoId: _items[index].productoId,
      nombreSnapshot: _items[index].nombreSnapshot,
      precioBaseSnapshot: _items[index].precioBaseSnapshot,
      cantidad: nuevaCantidad,
      modificadoresAplicados: _items[index].modificadoresAplicados,
    );
    notifyListeners();
  }

  void reemplazarItem(int index, ItemPedidoSnapshot nuevoItem) {
    _items[index] = nuevoItem;
    notifyListeners();
  }

  void limpiarCarrito() {
    _items.clear();
    notifyListeners();
  }

  /// Función Crítica: Envía el pedido a Firestore aplicando la inmutabilidad de precios.
  /// Retorna el ID del documento creado para rastrear el estado.
  Future<String?> crearPedido() async {
    if (_items.isEmpty || _mesaId == null) return null;

    try {
      List<Map<String, dynamic>> itemsSnapshot = _items.map((item) => item.toMap()).toList();

      final docRef = await _firestore.collection('pedidos').add({
        'mesa_id': _mesaId,
        'estado': 'pendiente',
        'items': itemsSnapshot,
        'total': totalPedido,
        'created_at': FieldValue.serverTimestamp(),
      });

      limpiarCarrito();
      _pedidoActivoId = docRef.id;

      // Enlazar el pedido con la mesa en Firestore
      await _firestore.collection('mesas').doc(_mesaId).update({
        'pedido_activo_id': docRef.id,
      });

      notifyListeners();
      return docRef.id;

    } catch (e) {
      print("Error al crear pedido: $e");
      rethrow;
    }
  }
}
