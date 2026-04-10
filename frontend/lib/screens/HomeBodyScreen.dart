// lib/screens/HomeBodyScreen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart';
import 'package:donapp_android/services/session_manager.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

// Importa todas las pantallas que vas a necesitar
import 'package:donapp_android/screens/trivia/pantallaSeleccion.dart';
import 'package:donapp_android/screens/Minigames/transfusion/transfusion.dart';
import 'package:donapp_android/screens/Simulacion/sim.dart';
import 'package:donapp_android/screens/map/map_screen.dart';
import 'package:donapp_android/screens/schedule/schedule_screen.dart';
import 'package:donapp_android/screens/campana/encuesta.dart';
import 'package:donapp_android/screens/historias/historias_screen.dart';
import 'package:donapp_android/screens/desafios/desafios_screen.dart';
import 'package:donapp_android/screens/ayuda/help_app_screen.dart';
import 'package:donapp_android/screens/ayuda/help_organization_screen.dart';
import 'package:donapp_android/screens/politica_privacidad_screen.dart';
import 'package:donapp_android/screens/aviso_legal_screen.dart';
import 'package:donapp_android/screens/login.dart';

// --- INICIO DE MODIFICACIÓN (NUEVOS IMPORTS) ---
// Nota: Ajusta estas rutas si tus archivos están en carpetas diferentes.
import 'package:donapp_android/screens/chatbot/ChatUsuario.dart'; 
import 'package:donapp_android/screens/formularioDonacion/formulario_donacion.dart';

import 'package:donapp_android/screens/games_home_screen.dart';
// --- FIN DE MODIFICACIÓN ---


class HomeBodyScreen extends StatefulWidget {
  const HomeBodyScreen({super.key});

  @override
  State<HomeBodyScreen> createState() => _HomeBodyScreenState();
}

class _HomeBodyScreenState extends State<HomeBodyScreen> {
  bool _isGuestUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    final isGuest = await SessionManager.isGuest();
    if (mounted) {
      setState(() => _isGuestUser = isGuest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      // El AppBar personalizado como en el prototipo
      appBar: _CustomAppBar(isGuest: _isGuestUser), // --- MODIFICACIÓN CA02 --- (Pasamos isGuest)
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- MODIFICACIÓN CA02 (INICIO) ---
            // Nuevo Widget de Progreso Prominente
            _ProgressSection(isGuest: _isGuestUser),
            // --- MODIFICACIÓN CA02 (FIN) ---

            // --- Carrusel Superior (Juegos) ---
            _TopCarousel(),
            const SizedBox(height: 24),

            // --- Sección Menú ---
            _SectionHeader(title: 'Menú', icon: Icons.menu_rounded),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _MenuGrid(isGuestUser: _isGuestUser),
            ),
            const SizedBox(height: 24),

            // --- Sección Juegos (Carrusel) ---
            _SectionHeader(title: 'Juegos', icon: Icons.sports_esports_rounded),
            const SizedBox(height: 16),
            _GameCarousel(),
            const SizedBox(height: 24),

            // --- Sección Legal ---
            _SectionHeader(title: 'Apartado Legal', icon: Icons.gavel_rounded),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _LegalGrid(),
            ),
            const SizedBox(height: 24),
            // --- Sección de Centro de Ayuda ---
            _SectionHeader(title: 'Centro de Ayuda', icon: Icons.help_outline_rounded),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _MenuGridButton(
                    label: 'FAQs de la App',
                    icon: Icons.question_answer_outlined,
                    color: Colors.indigo.shade400,
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HelpAppScreen()));
                    },
                  ),
                  _MenuGridButton(
                    label: 'Sobre DonApp',
                    icon: Icons.favorite_outline_rounded,
                    color: Colors.red.shade400,
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HelpOrganizationScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

      // --- INICIO DE MODIFICACIÓN (BOTÓN FLOTANTE DE CHAT) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Posición inferior izquierda
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatBot()),
          );
        },
        backgroundColor: AppColors.primary, // Usa el color primario de tu app
        child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
        tooltip: 'Asistente',
      ),
      // --- FIN DE MODIFICACIÓN ---
    );
  }
}

// -------------------------------------
// WIDGETS INTERNOS DE HOMEBODYSCREEN
// -------------------------------------

// --- AppBar Personalizado ---
class _CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isGuest;
  const _CustomAppBar({required this.isGuest}); // --- MODIFICACIÓN CA02 --- (Recibe isGuest)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      titleSpacing: 16,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  color: theme.shadowColor.withOpacity(0.06),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/images/icon.png', fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          Text(
            'Donapp',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onBackground,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
      actions: [
        isGuest
            ? Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: OutlinedButton(
                  onPressed: () {
                    SessionManager.clearSession();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: const Text('Acceder'),
                ),
              )
            : const Padding( // --- MODIFICACIÓN CA02 --- (Se quitó el texto "Donante Pro")
                padding: EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundImage: AssetImage('assets/images/avatar3.png'), 
                  radius: 18
                ),
              ),
      ],
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


// --- MODIFICACIÓN CA02 (INICIO) ---
// --- Nuevo Widget de Progreso ---
class _ProgressSection extends StatelessWidget {
  final bool isGuest;
  const _ProgressSection({required this.isGuest});

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      // Si es invitado, mostrar un prompt para iniciar sesión
      return _GuestPromptCard();
    }

    final theme = Theme.of(context);
    
    // --- DATOS DE EJEMPLO ---
    // Deberás reemplazar esto con los datos reales del usuario
    const int userLevel = 5;
    const String userTitle = "Donante Pro";
    const int currentStreak = 10;
    const int currentXp = 150;
    const int totalXpForLevel = 200;
    final double xpPercent = currentXp / totalXpForLevel;
    // --- FIN DE DATOS DE EJEMPLO ---

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Nivel y Racha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Columna Izquierda: Nivel
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "NIVEL $userLevel",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      userTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                // Columna Derecha: Racha
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "$currentStreak Días",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fila 2: Barra de Progreso XP
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Progreso XP",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      "$currentXp / $totalXpForLevel XP",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: xpPercent,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    color: AppColors.primary, // O el color que prefieras para la barra
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// --- Widget de prompt para invitados ---
class _GuestPromptCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: theme.colorScheme.onSurfaceVariant, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "¡Únete a la comunidad!",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "Inicia sesión para ver tu progreso y racha.",
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
// --- MODIFICACIÓN CA02 (FIN) ---


// --- Carrusel Superior ---
class _TopCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: PageView(
        controller: PageController(viewportFraction: 0.85), // Muestra parte de la siguiente tarjeta
        children: [
          _CarouselCard(
            title: '',
            // ¡Necesitarás crear esta imagen en tus assets!
            // Usa la imagen que te generé antes
            imagePath: 'assets/images/games_banner.png', 
            onTap: () {
              // Puedes llevar a una pantalla de "Juegos" o a la Trivia
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesHomeScreen()));
            },
          ),
          _CarouselCard(
            title: '',
            // ¡Necesitarás crear esta imagen en tus assets!
            imagePath: 'assets/images/historias_banner.png', 
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoriasScreen()));
            },
          ),
          _CarouselCard(
            title: '',
            // ¡Necesitarás crear esta imagen en tus assets!
            imagePath: 'assets/images/desafios_banner.png', 
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DesafiosScreen()));
            },
          ),
        ],
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _CarouselCard({required this.title, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
              // Fallback visual si la imagen no carga
              onError: (exception, stackTrace) {
                print("Error cargando imagen de banner: $imagePath");
              },
            ),
          ),
          // Fallback por si la imagen no existe
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: theme.colorScheme.primary.withOpacity(0.1), // Color de placeholder
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
            child: Stack(
              children: [
                // Placeholder Icon
                Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white.withOpacity(0.2),
                    size: 60,
                  ),
                ),
                // Título
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


// --- Grilla de Menú (2 columnas) ---
class _MenuGrid extends StatelessWidget {
  final bool isGuestUser;
  const _MenuGrid({required this.isGuestUser});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5, // Más anchos que altos
      children: [
        _MenuGridButton(
          label: 'Mapa',
          icon: Icons.map_outlined,
          color: Colors.red.shade300,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
          },
        ),
        _MenuGridButton(
          label: 'Agendar',
          icon: Icons.calendar_month_outlined,
          color: Colors.pink.shade300,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen()));
          },
        ),
        _MenuGridButton(
          label: 'Encuestas',
          icon: Icons.assignment_outlined,
          color: Colors.green.shade300,
          onTap: () {
            if (isGuestUser) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Necesitas iniciar sesión para ver encuestas.')));
            } else {
              // Asumo que tienes una pantalla EncuestaApp()
              Navigator.push(context, MaterialPageRoute(builder: (_) => EncuestaApp())); 
            }
          },
        ),
        _MenuGridButton(
          label: 'Historias',
          icon: Icons.auto_stories_outlined,
          color: Colors.orange.shade300,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoriasScreen()));
          },
        ),
        
        // --- INICIO DE MODIFICACIÓN (NUEVO BOTÓN DE DONAR) ---
        _MenuGridButton(
          label: 'Donar Ahora',
          icon: Icons.bloodtype_outlined, // Icono sugerido para donar
          color: Colors.red.shade600, // Un rojo más fuerte
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FormularioDonacion()),
            );
          },
        ),
        // --- FIN DE MODIFICACIÓN ---
      ],
    );
  }
}

class _MenuGridButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuGridButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Carrusel de Juegos (Horizontal) ---
class _GameCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _GameCard(
            title: 'Trivia de Mitos',
            description: 'Pon a prueba tu conocimiento y derriba mitos comunes.',
            // ¡Necesitarás crear esta imagen en tus assets!
            imagePath: 'assets/images/game_trivia.png', 
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NivelIntroScreen()));
            },
          ),
          _GameCard(
            title: 'Match de Sangre',
            description: 'Aprende sobre la compatibilidad de grupos sanguíneos.',
            // ¡Necesitarás crear esta imagen en tus assets!
            imagePath: 'assets/images/game_match.png', 
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BloodCompatibilityApp()));
            },
          ),
          _GameCard(
            title: 'Simulador',
            description: 'Vive la experiencia de tu primera donación sin agujas.',
            // ¡NecesitarS crear esta imagen en tus assets!
            imagePath: 'assets/images/game_simulador.png', 
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const JennyGamePage()));
            },
          ),
        ],
      ),
    );
  }
}

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
        width: 160,
        margin: const EdgeInsets.only(right: 12),
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
                  // Fallback visual
                  onError: (e, s) => print('Error cargando imagen: $imagePath'),
                ),
                color: theme.colorScheme.primary.withOpacity(0.1), // Color de placeholder
              ),
              // Muestra un ícono si la imagen no carga
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- Grilla Legal ---
class _LegalGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5, // Mismo ratio que el menú
      children: [
        _MenuGridButton(
          label: 'Aviso Legal',
          icon: Icons.gavel_rounded,
          color: Colors.grey.shade500,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AvisoLegalScreen()));
          },
        ),
        _MenuGridButton(
          label: 'Privacidad',
          icon: Icons.privacy_tip_rounded,
          color: Colors.blue.shade500,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PoliticaPrivacidadScreen(showContinue: true)));
          },
        ),
      ],
    );
  }
}