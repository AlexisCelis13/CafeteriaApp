import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/data_models.dart';
import '../providers/carrito_provider.dart';
import 'producto_detalle_sheet.dart';
import 'estado_pedido_screen.dart';

class MenuDigitalScreen extends StatelessWidget {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SmartOrder - Menu'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () => _mostrarResumenCarrito(context),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('categorias')
                   .where('activa', isEqualTo: true)
                   .orderBy('orden_visual')
                   .snapshots(),
        builder: (context, snapshotCategorias) {
          if (snapshotCategorias.hasError) {
             print("Firestore Error (Categorias): ${snapshotCategorias.error}");
             return Center(child: Text("Error cargando categorias: ${snapshotCategorias.error}"));
          }
          if (!snapshotCategorias.hasData) return Center(child: CircularProgressIndicator());
          
          final categorias = snapshotCategorias.data!.docs
              .map((doc) => Categoria.fromFirestore(doc))
              .toList();

          if (categorias.isEmpty) return Center(child: Text("No hay categorias activas."));

          return DefaultTabController(
            length: categorias.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  labelColor: Theme.of(context).primaryColor,
                  tabs: categorias.map((cat) => Tab(text: cat.nombre)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: categorias.map((cat) => _ListaProductosCategoria(categoriaId: cat.id)).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarResumenCarrito(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => CarritoResumenWidget());
  }
}

class _ListaProductosCategoria extends StatelessWidget {
  final String categoriaId;
  const _ListaProductosCategoria({required this.categoriaId});

  @override
  Widget build(BuildContext context) {
    final _db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('productos')
                 .where('categoria_id', isEqualTo: categoriaId)
                 .where('disponible', isEqualTo: true)
                 .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final productos = snapshot.data!.docs.map((doc) => Producto.fromFirestore(doc)).toList();

        if (productos.isEmpty) return Center(child: Text("Sin productos en esta categoria"));

        return ListView.builder(
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final proc = productos[index];
            return ListTile(
              leading: proc.imagenUrl != null 
                  ? Image.network(proc.imagenUrl!, width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => Icon(Icons.fastfood, size: 40))
                  : Icon(Icons.fastfood, size: 40),
              title: Text(proc.nombre),
              subtitle: Text(proc.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Text('\$${proc.precio.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () => _abrirDetalleProducto(context, proc),
            );
          },
        );
      },
    );
  }

  void _abrirDetalleProducto(BuildContext context, Producto producto) {
     showModalBottomSheet(
       context: context, 
       isScrollControlled: true, 
       builder: (_) => ProductoDetalleSheet(producto: producto)
     );
  }
}

class CarritoResumenWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tu Pedido", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (carrito.items.isNotEmpty)
                TextButton(
                  onPressed: () => carrito.limpiarCarrito(),
                  child: Text("Vaciar", style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
          Divider(),
          if (carrito.items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[300]),
                  SizedBox(height: 10),
                  Text("Tu carrito esta vacio", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          else
            ...carrito.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final modTexto = item.modificadoresAplicados.isNotEmpty
                  ? item.modificadoresAplicados.map((m) => m.nombre).join(', ')
                  : '';
              return _buildCartItem(context, carrito, index, item, modTexto);
            }).toList(),
          if (carrito.items.isNotEmpty) ...[
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('\$${carrito.totalPedido.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              ],
            ),
            SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
                  final parentNav = Navigator.of(context);
                  final parentContext = parentNav.context;
                  final pedidoId = await carrito.crearPedido('MESA-01');
                  parentNav.pop();
                  if (pedidoId != null) {
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (_) => EstadoPedidoScreen(pedidoId: pedidoId),
                      ),
                    );
                  }
                },
                child: Text("Confirmar Pedido", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CarritoProvider carrito, int index, ItemPedidoSnapshot item, String modTexto) {
    return GestureDetector(
      onTap: () => _editarItem(context, index, item),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.nombreSnapshot, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                    ],
                  ),
                  if (modTexto.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(modTexto, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ),
                  SizedBox(height: 8),
                  Text('\$${item.subtotalItem.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 15)),
                ],
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: () => carrito.eliminarItem(index),
                  child: Icon(Icons.delete_outline, color: Colors.red[400], size: 22),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => carrito.actualizarCantidad(index, item.cantidad - 1),
                        child: Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 16)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${item.cantidad}', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      InkWell(
                        onTap: () => carrito.actualizarCantidad(index, item.cantidad + 1),
                        child: Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 16)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editarItem(BuildContext context, int index, ItemPedidoSnapshot item) async {
    // Guardar referencia al Navigator padre ANTES de cerrar el bottom sheet
    final parentNavigator = Navigator.of(context);
    final parentContext = parentNavigator.context;
    parentNavigator.pop(); // Cerrar carrito

    final db = FirebaseFirestore.instance;
    final doc = await db.collection('productos').doc(item.productoId).get();
    if (!doc.exists) return;
    final producto = Producto.fromFirestore(doc);
    final modSnap = await db.collection('modificadores_productos')
        .where('producto_id', isEqualTo: item.productoId).get();
    Map<String, OpcionModificador> seleccionesReconstruidas = {};
    for (var modDoc in modSnap.docs) {
      final mod = ModificadorProducto.fromFirestore(modDoc);
      for (var aplicado in item.modificadoresAplicados) {
        if (mod.opciones.any((op) => op.nombre == aplicado.nombre)) {
          seleccionesReconstruidas[mod.id] = aplicado;
        }
      }
    }
    // Usar el contexto del Navigator padre que sigue vivo
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      builder: (_) => ProductoDetalleSheet(
        producto: producto,
        editIndex: index,
        initialCantidad: item.cantidad,
        initialSelecciones: seleccionesReconstruidas,
      ),
    );
  }
}
