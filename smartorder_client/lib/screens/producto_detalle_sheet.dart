import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/data_models.dart';
import '../providers/carrito_provider.dart';

class ProductoDetalleSheet extends StatefulWidget {
  final Producto producto;
  final int? editIndex; // null = agregar nuevo, int = editar existente en carrito
  final int? initialCantidad;
  final Map<String, OpcionModificador>? initialSelecciones;

  const ProductoDetalleSheet({
    Key? key, 
    required this.producto,
    this.editIndex,
    this.initialCantidad,
    this.initialSelecciones,
  }) : super(key: key);

  @override
  _ProductoDetalleSheetState createState() => _ProductoDetalleSheetState();
}

class _ProductoDetalleSheetState extends State<ProductoDetalleSheet> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late Future<QuerySnapshot> _modificadoresFuture;
  
  // Estado local para mantener las opciones seleccionadas
  Map<String, OpcionModificador> _selecciones = {};
  int _cantidad = 1;
  bool _listoParaAgregar = false;

  @override
  void initState() {
    super.initState();

    // Pre-llenar si estamos en modo edición
    if (widget.initialCantidad != null) _cantidad = widget.initialCantidad!;
    if (widget.initialSelecciones != null) _selecciones = Map.from(widget.initialSelecciones!);

    // Cacheamos el Future para evitar re-ejecuciones en cada setState
    _modificadoresFuture = _db.collection('modificadores_productos')
                              .where('producto_id', isEqualTo: widget.producto.id)
                              .get().then((snapshot) {
                                _verificarObligatoriosInicial(snapshot);
                                return snapshot;
                              });
  }

  void _verificarObligatoriosInicial(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) {
      if(mounted) setState(() => _listoParaAgregar = true);
      return;
    }
    final modificadores = snapshot.docs.map((doc) => ModificadorProducto.fromFirestore(doc)).toList();
    bool todosValidos = true;
    for (var mod in modificadores) {
      if (mod.obligatorio) {
        todosValidos = false;
        break;
      }
    }
    if (todosValidos && mounted) {
      setState(() => _listoParaAgregar = true);
    }
  }

  double get _precioTotalDinamico {
    double totalExtras = _selecciones.values.fold(0.0, (sum, opcion) => sum + opcion.precioAdicional);
    return (widget.producto.precio + totalExtras) * _cantidad;
  }

  void _validarObligatorios(List<ModificadorProducto> modificadores) {
    bool todosValidos = true;
    for (var mod in modificadores) {
      if (mod.obligatorio && !_selecciones.containsKey(mod.id)) {
        todosValidos = false;
        break;
      }
    }
    setState(() {
      _listoParaAgregar = todosValidos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCabecera(),
          
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Descripción", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 5),
                  Text(widget.producto.descripcion, style: TextStyle(color: Colors.grey[600])),
                  Divider(height: 30),
                  _buildSeccionModificadores(),
                ],
              ),
            ),
          ),
          
          _buildBarraAccionInferior(),
        ],
      ),
    );
  }

  Widget _buildCabecera() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.producto.imagenUrl != null)
             ClipRRect(
               borderRadius: BorderRadius.circular(10),
               child: Image.network(
                  widget.producto.imagenUrl!, 
                  width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Icon(Icons.fastfood, size: 60, color: Colors.grey),
               ),
             )
          else
            Icon(Icons.fastfood, size: 60, color: Colors.grey),
            
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.producto.nombre, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('\$${widget.producto.precio.toStringAsFixed(2)} Base', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context))
        ],
      ),
    );
  }

  Widget _buildSeccionModificadores() {
     return FutureBuilder<QuerySnapshot>(
      future: _modificadoresFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Text('Error al cargar opciones');
        
        final modificadores = snapshot.data!.docs
            .map((doc) => ModificadorProducto.fromFirestore(doc))
            .toList();

        if (modificadores.isEmpty) {
           return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: modificadores.map((modificador) => _buildGrupoModificador(modificador, modificadores)).toList(),
        );
      },
    );
  }

  Widget _buildGrupoModificador(ModificadorProducto modificador, List<ModificadorProducto> todosLosModificadores) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(modificador.nombre, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (modificador.obligatorio) 
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(10)),
                    child: Text('Obligatorio', style: TextStyle(color: Colors.red[800], fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
          SizedBox(height: 10),
          ...modificador.opciones.map((opcion) {
            bool isActive = _selecciones[modificador.id]?.nombre == opcion.nombre;
            return InkWell(
              onTap: () {
                setState(() {
                  _selecciones[modificador.id] = opcion;
                });
                _validarObligatorios(todosLosModificadores);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                child: Row(
                  children: [
                    Icon(isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked, 
                         color: isActive ? Theme.of(context).primaryColor : Colors.grey),
                    SizedBox(width: 15),
                    Expanded(child: Text(opcion.nombre, style: TextStyle(fontSize: 16))),
                    if (opcion.precioAdicional > 0)
                      Text('+\$${opcion.precioAdicional.toStringAsFixed(2)}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBarraAccionInferior() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                  ),
                  Text('$_cantidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => setState(() => _cantidad++),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _listoParaAgregar ? Theme.of(context).primaryColor : Colors.grey[400],
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _listoParaAgregar ? _agregarAlCarrito : null,
                child: _listoParaAgregar 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Agregar • ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('\$${_precioTotalDinamico.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    )
                  : Text(
                      'Seleccione opciones',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _agregarAlCarrito() {
    final snapshotItem = ItemPedidoSnapshot(
      productoId: widget.producto.id,
      nombreSnapshot: widget.producto.nombre, 
      precioBaseSnapshot: widget.producto.precio, 
      cantidad: _cantidad,
      modificadoresAplicados: _selecciones.values.toList(),
    );

    final carritoProvider = context.read<CarritoProvider>();

    if (widget.editIndex != null) {
      // Modo edición: reemplazar el item existente
      carritoProvider.reemplazarItem(widget.editIndex!, snapshotItem);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.producto.nombre} actualizado')),
      );
    } else {
      // Modo agregar: nuevo item
      carritoProvider.agregarAlCarrito(snapshotItem);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.producto.nombre} agregado al pedido')),
      );
    }
  }
}
