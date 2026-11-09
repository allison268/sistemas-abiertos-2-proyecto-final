import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/store_service.dart';
import '../widgets/ui_kit.dart';
import 'checkout_screen.dart';

IconData storeIcon(String name) {
  switch (name) {
    case 'workspace_premium':
      return Icons.workspace_premium_rounded;
    case 'flag':
      return Icons.flag_rounded;
    case 'volunteer_activism':
      return Icons.volunteer_activism_rounded;
    case 'style':
      return Icons.style_rounded;
    default:
      return Icons.shopping_bag_rounded;
  }
}

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final StoreService _store = StoreService();
  List<StoreProduct>? _products;
  List<Purchase> _purchases = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final products = await _store.products();
      final purchases = await _store.myPurchases();
      if (!mounted) return;
      setState(() {
        _products = products;
        _purchases = purchases;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  bool _owned(StoreProduct p) =>
      !p.repetible && _purchases.any((c) => c.clave == p.clave);

  Future<void> _buy(StoreProduct p) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CheckoutScreen(product: p)),
    );
    if (done == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tienda',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: _products == null ? _buildWaiting() : _buildList(),
        ),
      ),
    );
  }

  Widget _buildWaiting() {
    if (_error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 54, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 15),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: GradientButton(
                label: 'Reintentar',
                icon: Icons.refresh_rounded,
                onPressed: _load,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.hero,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.storefront_rounded,
                        color: AppColors.gold, size: 38),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tienda Memory Honduras',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Apoya el juego y presume tu insignia',
                            style: TextStyle(
                              color: Color(0xFFD6E4FF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle(
                icon: Icons.shopping_bag_rounded,
                text: 'Productos',
              ),
              const SizedBox(height: 12),
              ..._products!.map(_productCard),
              if (_purchases.isNotEmpty) ...[
                const SizedBox(height: 14),
                const SectionTitle(
                  icon: Icons.receipt_long_rounded,
                  text: 'Mis compras',
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: _purchases.map((c) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    '${c.referencia} · ${c.fecha}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              money(c.monto),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.blue,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productCard(StoreProduct p) {
    final owned = _owned(p);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppColors.hero,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: Icon(storeIcon(p.icono), color: AppColors.gold, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.descripcion,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        money(p.precio),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.blue,
                        ),
                      ),
                      const Spacer(),
                      if (owned)
                        const InfoPill(
                          icon: Icons.check_rounded,
                          text: 'Adquirido',
                          color: AppColors.success,
                        )
                      else
                        SizedBox(
                          width: 118,
                          child: GradientButton(
                            label: 'Comprar',
                            height: 42,
                            onPressed: () => _buy(p),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
