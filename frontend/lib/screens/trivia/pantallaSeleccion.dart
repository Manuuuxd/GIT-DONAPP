// lib/screens/trivia/pantallaSeleccion.dart

import 'package:flutter/material.dart';
import '../Usuario/getlevel.dart'; // Tu lógica de nivel (SIN CAMBIOS)
import 'question_screen.dart'; // Importamos la nueva pantalla de chat

class NivelIntroScreen extends StatefulWidget {
  const NivelIntroScreen({super.key});

  @override
  State<NivelIntroScreen> createState() => _NivelIntroScreenState();
}

class _NivelIntroScreenState extends State<NivelIntroScreen> {
  int userLevel = 0;
  bool isLoading = true;

  // Lógica de Backend (SIN CAMBIOS)
  @override
  void initState() {
    super.initState();
    fetchUserLevel().then((nivel) {
      setState(() {
        userLevel = nivel as int;
        isLoading = false;
      });
    }).catchError((_) {
      setState(() {
        isLoading = false;
        userLevel = 1; // Asumimos nivel 1 si falla la carga
      });
    });
  }

  // Lógica de Backend (SIN CAMBIOS)
  void _startTrivia(String dificultad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionScreen(dificultad: dificultad),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- NUEVA UI (Estilo Rootd) ---
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trivia de Mitos"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Personaje de la sección
          Center(
            child: Image.asset(
              'assets/images/facilito.png', // <-- Tu personaje
              height: 100,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Aprende y Gana XP",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Selecciona una lección para poner a prueba tus conocimientos.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Tarjeta de Nivel Inicial
          _LessonCard(
            context: context,
            title: "Nivel Inicial",
            subtitle: "Conceptos básicos y mitos comunes. (+10 XP)",
            icon: Icons.school_outlined,
            color: Colors.green,
            isLocked: false, 
            onTap: () => _startTrivia("Inicial"),
          ),
          
          // Tarjeta de Nivel Avanzado
          _LessonCard(
            context: context,
            title: "Nivel Avanzado",
            subtitle: "Compatibilidad y procesos. (+20 XP)",
            icon: Icons.star_outline_rounded,
            color: Colors.blue,
            isLocked: userLevel < 4, // Tu lógica de nivel (SIN CAMBIOS)
            onTap: () => _startTrivia("Avanzado"),
          ),

          // Tarjeta de Nivel Experto
          _LessonCard(
            context: context,
            title: "Nivel Experto",
            subtitle: "Casos complejos y datos técnicos. (+30 XP)",
            icon: Icons.shield_outlined,
            color: Colors.purple,
            isLocked: userLevel < 7, // Tu lógica de nivel (SIN CAMBIOS)
            onTap: () => _startTrivia("Experto"),
          ),

          const SizedBox(height: 24),
          
          // ▼▼▼ ¡AQUÍ ESTÁ LA SECCIÓN DE INFORMACIÓN REDISEÑADA! ▼▼▼
          _buildInfoSection(context),
        ],
      ),
    );
  }

  // Widget para la tarjeta de lección
  Widget _LessonCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    Color cardColor = isLocked
        ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
        : theme.colorScheme.surface;
    Color contentColor = isLocked ? theme.colorScheme.onSurface.withOpacity(0.4) : color;

    return Card(
      elevation: isLocked ? 0 : 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(isLocked ? Icons.lock_outline : icon, size: 32, color: contentColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: contentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLocked ? "Completa los niveles anteriores" : subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isLocked 
                          ? theme.colorScheme.onSurface.withOpacity(0.4) 
                          : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLocked)
                Icon(Icons.play_circle_fill_rounded, size: 32, color: contentColor.withOpacity(0.8)),
            ],
          ),
        ),
      ),
    );
  }

  // ▼▼▼ WIDGET DE INFORMACIÓN REDISEÑADO ▼▼▼
  Widget _buildInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurfaceVariant;

    // Usamos un ExpansionTile para que sea un menú desplegable
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        // Título cuando está cerrado
        leading: Icon(Icons.info_outline_rounded, color: iconColor),
        title: Text(
          "Reglas y Puntuación",
          style: TextStyle(fontWeight: FontWeight.bold, color: iconColor),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        // Contenido cuando se expande
        children: [
        _InfoRow(
          context: context,
          iconData: Icons.school_rounded, // ✅ CORREGIDO
          color: Colors.green,
          title: "Nivel Inicial", 
          text: "✅ +10 XP | ❌ +2 XP"
        ),
        _InfoRow(
          context: context,
          iconData: Icons.star_rounded, // ✅ CORREGIDO
          color: Colors.blue,
          title: "Nivel Avanzado", 
          text: "✅ +20 XP | ❌ +5 XP"
        ),
        _InfoRow(
          context: context,
          iconData: Icons.shield_rounded, // ✅ CORREGIDO
          color: Colors.purple,
          title: "Nivel Experto", 
          text: "✅ +30 XP | ❌ +8 XP"
        ),
        
        const Divider(height: 24),
          
          const Divider(height: 24),
          
          Text(
            "Bonificaciones 🏆", 
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          _InfoRow(context: context, iconData: Icons.check_circle, color: Colors.amber, text: "3 aciertos seguidos: +10 XP"),
          _InfoRow(context: context, iconData: Icons.timer, color: Colors.amber, text: "Respuesta en < 5s: +5 XP"),
          _InfoRow(context: context, iconData: Icons.extension, color: Colors.amber, text: "Completar categoría: +50 XP"),
        ],
      ),
    );
  }

  // Un pequeño widget de ayuda para las filas de información
  Widget _InfoRow({
    required BuildContext context,
    String? title,
    required String text,
    IconData? iconData, // Permitimos IconData
    Color? color
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (iconData != null)
            Icon(iconData, color: color ?? theme.colorScheme.onSurfaceVariant, size: 20),
          
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color ?? theme.colorScheme.onSurface,
                    ),
                  ),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurfaceVariant
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}