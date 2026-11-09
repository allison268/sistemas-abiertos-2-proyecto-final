import 'api_service.dart';

/// Producto de la tienda, tal como lo manda el servidor.
class StoreProduct {
  final String clave;
  final String nombre;
  final String descripcion;
  final double precio;
  final String icono;
  final bool repetible;

  const StoreProduct({
    required this.clave,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.icono,
    required this.repetible,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> j) => StoreProduct(
    clave: '${j['clave']}',
    nombre: '${j['nombre']}',
    descripcion: '${j['descripcion']}',
    precio: (j['precio'] as num).toDouble(),
    icono: '${j['icono']}',
    repetible: j['repetible'] == true,
  );
}

/// Compra ya registrada en el servidor.
class Purchase {
  final String clave;
  final String nombre;
  final double monto;
  final String metodo;
  final String referencia;
  final String fecha;

  const Purchase({
    required this.clave,
    required this.nombre,
    required this.monto,
    required this.metodo,
    required this.referencia,
    required this.fecha,
  });

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
    clave: '${j['clave']}',
    nombre: '${j['nombre']}',
    monto: (j['monto'] as num).toDouble(),
    metodo: '${j['metodo']}',
    referencia: '${j['referencia']}',
    fecha: '${j['fecha']}',
  );
}

class PurchaseResult {
  final bool success;
  final String message;
  final String? referencia;

  const PurchaseResult({
    required this.success,
    required this.message,
    this.referencia,
  });
}

String money(double v) => 'L ${v.toStringAsFixed(2)}';

/// Habla con la API de la tienda. El pago es simulado: solo se manda al
/// servidor el método y los últimos 4 dígitos, nunca el número completo.
class StoreService {
  final ApiService _api = ApiService();

  Future<List<StoreProduct>> products() async {
    final resp = await _api.get('/api/tienda/productos');
    if (!resp.ok || resp.data is! List) {
      throw ApiException(resp.message);
    }
    return (resp.data as List)
        .map((e) => StoreProduct.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Purchase>> myPurchases() async {
    final resp = await _api.get('/api/tienda/mis-compras', auth: true);
    if (!resp.ok || resp.data is! List) {
      throw ApiException(resp.message);
    }
    return (resp.data as List)
        .map((e) => Purchase.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<PurchaseResult> buy({
    required String clave,
    required String metodo,
    required String ultimos4,
  }) async {
    try {
      final resp = await _api.post('/api/tienda/comprar', {
        'clave': clave,
        'metodo': metodo,
        'ultimos4': ultimos4,
      }, auth: true);
      if (resp.ok && resp.data is Map) {
        return PurchaseResult(
          success: true,
          message: '${(resp.data as Map)['mensaje']}',
          referencia: '${(resp.data as Map)['referencia']}',
        );
      }
      return PurchaseResult(success: false, message: resp.message);
    } on ApiException catch (e) {
      return PurchaseResult(success: false, message: e.message);
    }
  }
}
