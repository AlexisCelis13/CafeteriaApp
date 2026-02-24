import 'package:cloud_firestore/cloud_firestore.dart';

// --- CATÁLOGO ---

class Categoria {
  final String id;
  final String nombre;
  final int ordenVisual;
  final String? iconoUrl;

  Categoria({required this.id, required this.nombre, required this.ordenVisual, this.iconoUrl});

  factory Categoria.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Categoria(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      ordenVisual: data['orden_visual'] ?? 0,
      iconoUrl: data['icono_url'],
    );
  }
}

class Producto {
  final String id;
  final String categoriaId;
  final String nombre;
  final String descripcion;
  final double precio;
  final bool disponible;
  final String? imagenUrl;

  Producto({
    required this.id, required this.categoriaId, required this.nombre,
    required this.descripcion, required this.precio, required this.disponible, this.imagenUrl
  });

  factory Producto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Producto(
      id: doc.id,
      categoriaId: data['categoria_id'] ?? '',
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      precio: (data['precio'] ?? 0).toDouble(),
      disponible: data['disponible'] ?? false,
      imagenUrl: data['imagen_url'],
    );
  }
}

class ModificadorProducto {
  final String id;
  final String productoId;
  final String nombre;
  final bool obligatorio;
  final List<OpcionModificador> opciones;

  ModificadorProducto({
    required this.id, required this.productoId, required this.nombre, 
    required this.obligatorio, required this.opciones
  });

  factory ModificadorProducto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    var listaOpciones = (data['opciones'] as List<dynamic>?)?.map(
      (op) => OpcionModificador.fromMap(op as Map<String, dynamic>)
    ).toList() ?? [];

    return ModificadorProducto(
      id: doc.id,
      productoId: data['producto_id'] ?? '',
      nombre: data['nombre'] ?? '',
      obligatorio: data['obligatorio'] ?? false,
      opciones: listaOpciones,
    );
  }
}

class OpcionModificador {
  final String nombre;
  final double precioAdicional;

  OpcionModificador({required this.nombre, required this.precioAdicional});

  factory OpcionModificador.fromMap(Map<String, dynamic> map) {
    return OpcionModificador(
      nombre: map['nombre'] ?? '',
      precioAdicional: (map['precio_adicional'] ?? 0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'precio_snapshot': precioAdicional, // NOTA: Esto se guarda como snapshot inmutable
  };
}

// --- TRANSACCIONAL (PEDIDOS) ---

class ItemPedidoSnapshot {
  final String productoId;
  final String nombreSnapshot;
  final double precioBaseSnapshot;
  final int cantidad;
  final List<OpcionModificador> modificadoresAplicados;

  ItemPedidoSnapshot({
    required this.productoId, required this.nombreSnapshot, 
    required this.precioBaseSnapshot, required this.cantidad, 
    required this.modificadoresAplicados
  });

  double get subtotalItem {
    double totalModificadores = modificadoresAplicados.fold(0, (sum, mod) => sum + mod.precioAdicional);
    return (precioBaseSnapshot + totalModificadores) * cantidad;
  }

  Map<String, dynamic> toMap() {
    return {
      'producto_id': productoId,
      'nombre': nombreSnapshot, // Snapshot
      'precio_snapshot': precioBaseSnapshot, // Snapshot
      'cantidad': cantidad,
      'modificadores_aplicados': modificadoresAplicados.map((m) => m.toMap()).toList(), // Snapshot
    };
  }
}
