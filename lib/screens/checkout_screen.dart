import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/store_service.dart';
import '../widgets/ui_kit.dart';
import 'store_screen.dart';

/// Agrupa el número de tarjeta de 4 en 4: 4242 4242 4242 4242.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Escribe el vencimiento como MM/AA.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final text = limited.length > 2
        ? '${limited.substring(0, 2)}/${limited.substring(2)}'
        : limited;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

bool _luhn(String number) {
  var sum = 0;
  var alternate = false;
  for (var i = number.length - 1; i >= 0; i--) {
    var d = int.parse(number[i]);
    if (alternate) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

class CheckoutScreen extends StatefulWidget {
  final StoreProduct product;

  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final StoreService _store = StoreService();

  String _method = 'tarjeta';
  bool _paying = false;
  String? _error;
  PurchaseResult? _result;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cardCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.blueLight),
      filled: true,
      fillColor: const Color(0xFFF1F5FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
      ),
    );
  }

  Future<void> _pay() async {
    if (_paying) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _paying = true;
      _error = null;
    });
    final last4 = _method == 'tarjeta'
        ? _cardCtrl.text.replaceAll(RegExp(r'\D'), '').substring(12)
        : '0000';
    // Pequeña espera para que se note el procesamiento del pago simulado.
    await Future.delayed(const Duration(milliseconds: 1400));
    final result = await _store.buy(
      clave: widget.product.clave,
      metodo: _method,
      ultimos4: last4,
    );
    if (!mounted) return;
    setState(() {
      _paying = false;
      if (result.success) {
        _result = result;
      } else {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _result == null ? 'Pago' : 'Compra lista',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: _result == null,
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _result == null ? _buildForm() : _buildSuccess(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    final p = widget.product;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.hero,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Icon(storeIcon(p.icono), color: AppColors.gold, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              p.nombre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            money(p.precio),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodChip(String value, IconData icon, String label) {
    final selected = _method == value;
    return Expanded(
      child: GestureDetector(
        onTap: _paying
            ? null
            : () => setState(() {
                _method = value;
                _error = null;
              }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.line,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : AppColors.blue),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? Colors.white : AppColors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final p = widget.product;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summary(),
          const SizedBox(height: 18),
          const SectionTitle(
            icon: Icons.payments_rounded,
            text: 'Método de pago',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _methodChip('tarjeta', Icons.credit_card_rounded, 'Tarjeta'),
              const SizedBox(width: 10),
              _methodChip(
                'paypal',
                Icons.account_balance_wallet_rounded,
                'PayPal',
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: _method == 'tarjeta' ? _cardFields() : _paypalFields(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF9A9A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          GradientButton(
            label: 'Pagar ${money(p.precio)}',
            icon: Icons.lock_rounded,
            loading: _paying,
            onPressed: _pay,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _cardFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          enabled: !_paying,
          textCapitalization: TextCapitalization.words,
          decoration: _decoration('Nombre en la tarjeta', Icons.person_outline),
          validator: (v) => (v == null || v.trim().length < 3)
              ? 'Escribe el nombre del titular'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _cardCtrl,
          enabled: !_paying,
          keyboardType: TextInputType.number,
          inputFormatters: [_CardNumberFormatter()],
          decoration: _decoration(
            'Número de tarjeta',
            Icons.credit_card_rounded,
            hint: '4242 4242 4242 4242',
          ),
          validator: (v) {
            final d = (v ?? '').replaceAll(' ', '');
            if (d.length != 16) return 'Debe tener 16 dígitos';
            if (!_luhn(d)) return 'Número de tarjeta no válido';
            return null;
          },
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryCtrl,
                enabled: !_paying,
                keyboardType: TextInputType.number,
                inputFormatters: [_ExpiryFormatter()],
                decoration: _decoration(
                  'Vence',
                  Icons.calendar_month_rounded,
                  hint: 'MM/AA',
                ),
                validator: (v) {
                  final t = v ?? '';
                  if (t.length != 5) return 'MM/AA';
                  final month = int.tryParse(t.substring(0, 2)) ?? 0;
                  final year = 2000 + (int.tryParse(t.substring(3)) ?? 0);
                  if (month < 1 || month > 12) return 'Mes no válido';
                  final now = DateTime.now();
                  if (year < now.year ||
                      (year == now.year && month < now.month)) {
                    return 'Tarjeta vencida';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvvCtrl,
                enabled: !_paying,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: _decoration('CVV', Icons.password_rounded),
                validator: (v) =>
                    (v == null || v.length < 3) ? '3 dígitos' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _paypalFields() {
    return TextFormField(
      controller: _emailCtrl,
      enabled: !_paying,
      keyboardType: TextInputType.emailAddress,
      decoration: _decoration(
        'Correo de tu cuenta PayPal',
        Icons.alternate_email_rounded,
        hint: 'nombre@correo.com',
      ),
      validator: (v) {
        final t = (v ?? '').trim();
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
          return 'Escribe un correo válido';
        }
        return null;
      },
    );
  }

  Widget _buildSuccess() {
    final r = _result!;
    final p = widget.product;
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.gold, width: 3),
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 54),
        ),
        const SizedBox(height: 16),
        const Text(
          '¡Pago aprobado!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Gracias por apoyar Memory Honduras',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            children: [
              _receiptRow('Producto', p.nombre),
              _receiptRow('Monto', money(p.precio)),
              _receiptRow(
                'Método',
                _method == 'tarjeta' ? 'Tarjeta' : 'PayPal',
              ),
              _receiptRow('Referencia', r.referencia ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        GradientButton(
          label: 'Volver a la tienda',
          icon: Icons.storefront_rounded,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  Widget _receiptRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(k, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
