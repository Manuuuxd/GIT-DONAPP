// lib/screens/games_home_screen.dart

import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart';

// Importa las pantallas de CADA JUEGO
import 'package:donapp_android/screens/trivia/pantallaSeleccion.dart';
import 'package:donapp_android/screens/Minigames/transfusion/transfusion.dart';
import 'package:donapp_android/screens/Simulacion/sim.dart';


/// ---
/// Una clase simple para organizar los datos de los juegos
/// ---
class _GameItem {
  final String title;
  final String description;
  final String imagePath;
  final Widget destination;

  const _GameItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.destination,
  });
}


/// ---
/// LA PANTALLA PRINCIPAL DE JUEGOS
/// ---
class GamesHomeScreen extends StatelessWidget {
  const GamesHomeScreen({super.key});

  // Define tu lista de juegos aquí
  final List<_GameItem> allGames = const [
    _GameItem(
      title: 'Trivia de Mitos',
      description: 'Pon a prueba tu conocimiento y derriba mitos comunes.',
      imagePath: 'assets/images/game_trivia.png',
      destination: NivelIntroScreen(),
    ),
    _GameItem(
      title: 'Match de Sangre',
      description: 'Aprende sobre la compatibilidad de grupos sanguíneos.',
      imagePath: 'assets/images/game_match.png',
      destination: BloodCompatibilityApp(),
    ),
    _GameItem(
      title: 'Simulador',
      description: 'Vive la experiencia de tu primera donación sin agujas.',
      imagePath: 'assets/images/game_simulador.png',
      destination: JennyGamePage(),
    ),
    // Puedes agregar más juegos aquí fácilmente
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 1. AppBar simple con botón de regreso
      appBar: AppBar(
        title: const Text('Juegos'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onBackground, // Color de texto/iconos
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            
            // 2. Reutilizamos el banner principal de juegos
            _CarouselCard(
              title: '',
              imagePath: 'assets/images/games_banner.png',
              onTap: () {
                // No hace nada al tocar, ya estamos en la pantalla de juegos
              },
            ),
            const SizedBox(height: 24),

            // 3. Reutilizamos el encabezado de sección
            _SectionHeader(
              title: 'Todos los Juegos',
              icon: Icons.sports_esports_rounded,
            ),
            const SizedBox(height: 16),

            // 4. Una GRRILA con todos los juegos, usando _GameCard
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columnas
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 160 / 220, // (Ancho / Alto) de _GameCard
                ),
                itemCount: allGames.length,
                shrinkWrap: true, // Para que quepa en el SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final game = allGames[index];
                  
                  // 5. Reutilizamos la tarjeta de juego
                  return _GameCard(
                    title: game.title,
                    description: game.description,
                    imagePath: game.imagePath,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => game.destination),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24), // Espacio al final
          ],
        ),
      ),
    );
  }
}


// ===================================================================
// WIDGETS COPIADOS DE HOMEBODYSCREEN.DART PARA MANTENER LA ESTÉTICA
// ===================================================================

// --- Encabezado de Sección (rojo) ---
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary, // Asumo que AppColors.primary es tu rojo
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Tarjeta de Banner (Copiada de _TopCarousel) ---
class _CarouselCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;
  const _CarouselCard({required this.title, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Agregamos el mismo padding que tenías en _TopCarousel
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 148, // Ajustamos la altura (180 - 16*2 de padding vertical)
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {
                print("Error cargando imagen de banner: $imagePath");
              },
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: theme.colorScheme.primary.withOpacity(0.1),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white.withOpacity(0.2),
                    size: 60,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Tarjeta de Juego (Copiada de _GameCarousel) ---
// IMPORTANTE: He quitado el 'margin' que tenía
class _GameCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // width: 160, // El GridView maneja el ancho
        // margin: const EdgeInsets.only(right: 12), // QUITADO para el GridView
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                  onError: (e, s) => print('Error cargando imagen: $imagePath'),
                ),
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Center(
                child: Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3, // Ajustado para que quepa en el aspect ratio
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}