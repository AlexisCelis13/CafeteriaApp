import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data_models.dart';

class CarritoProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ItemPedidoSnapshot> _items = [];
  String? _pedidoActivoId;
  
  List<ItemPedidoSnapshot> get items => _items;
  String? get pedidoActivoId => _pedidoActivoId;

  double get totalPedido => _items.fold(0, (sum, item) => sum + item.subtotalItem);

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
  Future<String?> crearPedido(String mesaId) async {
    if (_items.isEmpty) return null;

    try {
      List<Map<String, dynamic>> itemsSnapshot = _items.map((item) => item.toMap()).toList();

      final docRef = await _firestore.collection('pedidos').add({
        'mesa_id': mesaId,
        'estado': 'pendiente',
        'items': itemsSnapshot,
        'total': totalPedido,
        'created_at': FieldValue.serverTimestamp(),
      });

      limpiarCarrito();
      _pedidoActivoId = docRef.id;
      notifyListeners();
      return docRef.id;

    } catch (e) {
      print("Error al crear pedido: $e");
      rethrow;
    }
  }
}
