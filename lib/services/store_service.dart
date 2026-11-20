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

/// Configuración de PayPal que manda el servidor.
class PayPalConfig {
  final bool activo;
  final String modo; // 'sandbox' (pruebas) o 'live' (dinero real)
  final double lempirasPorDolar;

  const PayPalConfig({
    required this.activo,
    required this.modo,
    required this.lempirasPorDolar,
  });

  double enDolares(double lempiras) => lempiras / lempirasPorDolar;
}

/// Orden de PayPal recién creada: [url] es la página oficial de pago.
class PayPalOrder {
  final String id;
  final String url;
  final double montoUsd;

  const PayPalOrder({required this.id, required this.url, required this.montoUsd});
}

/// Cómo va un pago de PayPal: creada, procesando, completada, cancelada o fallida.
class PayPalStatus {
  final String estado;
  final String? referencia;

  const PayPalStatus({required this.estado, this.referencia});
}

/// Habla con la API de la tienda.
/// - Si el servidor tiene PayPal configurado, el pago es real y se hace en la
///   página oficial de PayPal (con cuenta PayPal o con tarjeta).
/// - Si no, se usa el pago simulado original: solo se manda al servidor el
///   método y los últimos 4 dígitos, nunca el número completo.
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

  /// Pregunta al servidor si el pago real con PayPal está configurado.
  Future<PayPalConfig> payPalConfig() async {
    try {
      final resp = await _api.get('/api/paypal/config');
      if (resp.ok && resp.data is Map) {
        final d = resp.data as Map;
        return PayPalConfig(
          activo: d['activo'] == true,
          modo: '${d['modo']}',
          lempirasPorDolar: (d['lempirasPorDolar'] as num?)?.toDouble() ?? 27,
        );
      }
    } on ApiException catch (_) {}
    return const PayPalConfig(activo: false, modo: 'sandbox', lempirasPorDolar: 27);
  }

  /// Crea la orden en PayPal (a través del servidor Rocky) y devuelve el enlace de pago.
  Future<PayPalOrder> createPayPalOrder({
    required String clave,
    required String metodo,
  }) async {
    final resp = await _api.post(
      '/api/paypal/crear-orden',
      {'clave': clave, 'metodo': metodo},
      auth: true,
      timeout: const Duration(seconds: 30),
    );
    if (!resp.ok || resp.data is! Map) throw ApiException(resp.message);
    final d = resp.data as Map;
    return PayPalOrder(
      id: '${d['orden']}',
      url: '${d['url']}',
      montoUsd: (d['montoUsd'] as num).toDouble(),
    );
  }

  Future<PayPalStatus> payPalStatus(String orderId) async {
    final resp = await _api.get('/api/paypal/orden/$orderId', auth: true);
    if (!resp.ok || resp.data is! Map) throw ApiException(resp.message);
    final d = resp.data as Map;
    return PayPalStatus(
      estado: '${d['estado']}',
      referencia: d['referencia'] as String?,
    );
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
