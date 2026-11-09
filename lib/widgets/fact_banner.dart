import 'package:flutter/material.dart';

import 'ui_kit.dart';

/// Cartel que aparece al encontrar un par con el dato curioso del símbolo.
class FactBanner extends StatelessWidget {
  final String symbolName;
  final String? text;
  final bool fromAi;
  final VoidCallback onClose;

  const FactBanner({
    super.key,
    required this.symbolName,
    required this.text,
    required this.fromAi,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final loading = text == null;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppColors.hero,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.gold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              symbolName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: AppColors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InfoPill(
                            text: fromAi ? 'IA Gemini' : 'Servidor Rocky',
                            color: fromAi
                                ? AppColors.success
                                : AppColors.muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      loading
                          ? const Text(
                              'Buscando un dato curioso…',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppColors.muted,
                              ),
                            )
                          : Text(
                              text!,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                color: AppColors.ink,
                              ),
                            ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: const Color(0xFF9E9E9E),
                  splashRadius: 18,
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
