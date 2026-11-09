import 'package:flutter/material.dart';

import '../widgets/ui_kit.dart';

/// Integrantes del grupo. Edita esta lista para poner los nombres completos.
const List<String> kTeamMembers = [
  'Yarely Hissell Hernández Vigil',
  'Allison',
  'Carlos',
];

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Acerca de',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    _header(),
                    const SizedBox(height: 18),
                    _section(
                      Icons.school_rounded,
                      'Proyecto académico',
                      [
                        _row('Universidad', 'Universidad Tecnológica de Honduras (UTH)'),
                        _row('Clase', 'Programación para Sistemas Abiertos II'),
                        _row('Docente', 'Ing. Luis Valle'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _section(
                      Icons.groups_rounded,
                      'Equipo de desarrollo',
                      [for (final name in kTeamMembers) _member(name)],
                    ),
                    const SizedBox(height: 14),
                    _section(
                      Icons.memory_rounded,
                      'Tecnologías',
                      [
                        _row('App', 'Flutter y Dart'),
                        _row('Servidor', 'Node.js y Express en Rocky Linux'),
                        _row('Base de datos', 'MySQL'),
                        _row('Inteligencia artificial', 'Gemini'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Hecho con orgullo catracho',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppColors.hero,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
            ),
            child: ClipOval(
              child: Image.asset(
                'lib/splash y icono/icono_app.jpg',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 88,
                  height: 88,
                  child: Icon(Icons.flag_rounded, size: 44),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Memory Honduras',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Juego de memoria con los símbolos patrios\ny los departamentos de Honduras',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFD6E4FF), fontSize: 13.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Versión 1.0',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(IconData icon, String title, List<Widget> children) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(icon: icon, text: title),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _member(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.sky,
            child: Icon(Icons.person_rounded, size: 18, color: AppColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
