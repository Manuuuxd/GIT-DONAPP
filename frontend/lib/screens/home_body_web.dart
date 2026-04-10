// Archivo: home_body_web.dart (COMPLETO Y CORREGIDO)

import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart';
import 'package:donapp_android/screens/home/widgets/home_header.dart';
import 'package:donapp_android/screens/home/widgets/admin_panel.dart'; // Import original
import 'package:donapp_android/screens/home/home_controller.dart';
import 'package:donapp_android/screens/campanias/campanias_screen.dart';

// --- IMPORTAMOS LOS WIDGETS DE PASOS CORREGIDOS ---
import 'formularioDonacion/intro_step.dart';
import 'formularioDonacion/eligibility_step.dart';
import 'formularioDonacion/location_step.dart';
import 'formularioDonacion/datetime_step.dart';
import 'formularioDonacion/personal_data_step.dart';
import 'formularioDonacion/confirmation_step.dart';
import 'formularioDonacion/FormularioResultScreen.dart'; 
// --- FIN IMPORTS ---

import 'package:donapp_android/screens/estadisticas_camp/stats_page.dart';

import 'admin/filtro_usuarios.dart';
import 'campana/encuesta.dart';
import 'chat_asist/ChatAsistenteIA.dart';
import 'home/widgets/dashboard_page.dart';

// --- IMPORTS AÑADIDOS PARA CONTACTO ---
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// --- FIN IMPORTS AÑADIDOS ---


// --- VISTA 1: PÁGINA DE INVITADO (HU79B) ---
class GuestInformativePage extends StatefulWidget {
  final HomeController controller;
  const GuestInformativePage({Key? key, required this.controller}) : super(key: key);

  @override
  State<GuestInformativePage> createState() => _GuestInformativePageState();
}

class _GuestInformativePageState extends State<GuestInformativePage> {
  
  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _offerKey = GlobalKey();   
  final GlobalKey _teamKey = GlobalKey();     
  final GlobalKey _contactKey = GlobalKey(); 
  final GlobalKey _howToDonateKey = GlobalKey(); 

  final ScrollController _scrollController = ScrollController();

  static const Color donAppPeach = Color.fromARGB(255, 255, 224, 208);
  static const Color donAppRed = Color(0xFFE85C54);
  static const Color donAppText = Color(0xFF333333);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- Método para lanzar URLs ---
  Future<void> _launchURL(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, 
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: donAppPeach,
        elevation: 0,
        toolbarHeight: 80,
        
        title: InkWell(
          onTap: () {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            );
          },
          child: Text(
            "DONAPP",
            style: TextStyle(
              color: donAppRed, 
              fontWeight: FontWeight.bold, 
              fontSize: 28
            ),
          ),
        ),
        actions: [
          // Este es el orden que venía en tu último código
          _navButton("Cómo donar", () => _scrollToSection(_howToDonateKey)),
          _navButton("Beneficios", () => _scrollToSection(_offerKey)),
          _navButton("Quiénes somos", () => _scrollToSection(_teamKey)),
          _navButton("Contacto", () => _scrollToSection(_contactKey)),
          SizedBox(width: 30),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: donAppRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/login'); 
              },
              child: Text("Iniciar Sesión"),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(context),
            
            Container(
              key: _overviewKey, 
              child: _buildAppOverviewSection(context) // <-- Fondo Blanco
            ),

            Container(
              key: _howToDonateKey,
              child: _buildHowToDonateSection(context), // <-- Fondo Gris
            ),
            
            Container(
              key: _offerKey, 
              child: _buildInfoSection(
                context,
                "¿Que ofrecemos?", 
                "En DonApp fomentamos la donación de sangre mediante tecnología, gamificación y comunicación con la comunidad. Queremos que donar sea una experiencia cercana, entretenida y accesible para todos. Nuestra app conecta donantes con centros de salud, facilita la programación de donaciones y ofrece recompensas para motivar la participación activa.",
                isAlternate: false, // <-- Fondo Blanco
              )
            ),
            
            Container(
              key: _teamKey, 
              child: _buildTeamSection(context) // <-- Fondo Gris (Cambiado)
            ),

            Container(
              key: _contactKey,
              child: _buildContactSection(context), // <-- Fondo Melocotón
            ),

          ],
        ),
      ),
    );
  }

  Widget _navButton(String text, VoidCallback onPressed) {
    // ... (sin cambios)
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(color: donAppText, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    // ... (sin cambios)
    return Container(
      color: donAppPeach,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "DONAPP",
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: donAppRed,
                    height: 1.1
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Porque donar sangre es donar vida",
                  style: TextStyle(
                    fontSize: 24,
                    color: donAppText.withOpacity(0.8),
                    fontStyle: FontStyle.italic
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: donAppRed, 
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                    textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return _DonationStepperDialog(isGuest: true); 
                      },
                    );
                  },
                  child: Text("Agendar una Donación"),
                ),
              ],
            ),
          ),
          
          Expanded(
            flex: 3,
            child: Container(
              height: 600,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/Web/home_movil.png',
                     fit: BoxFit.contain,
                  ),
                  Positioned(
                    bottom: -40,
                    right: 230,
                    child: Image.asset(
                      'assets/images/Donarin/17.png',
                      height: 250,
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppOverviewSection(BuildContext context) {
    // ... (sin cambios)
    return Container(
      color: Colors.white, // <-- FONDO BLANCO
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewText(
                  context,
                  "",
                  "Problematica",
                  "La donacion en Chile es baja, con solo un 3% de la poblacion donando regularmente. Esto genera escasez de sangre en hospitales y dificulta la atencion medica oportuna."
                ),
                SizedBox(height: 40),
                _buildOverviewText(
                  context,
                  "",
                  "Solución",
                  "Generamos un sistema multidifusion que conecta donantes, centros de salud y organizaciones. Usamos tecnologia para facilitar la donacion, gamificacion para motivar a los usuarios y comunicación con IA para crear una comunidad activa."
                ),
              ],
            )
          ),
          SizedBox(width: 60),
          Expanded(
            flex: 3, 
            child: Container(
              height: 400,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    'assets/images/Web/mapa.png', 
                    fit: BoxFit.contain,
                    height: 400,
                  ),
                  Positioned(
                    bottom: -20, 
                    left: 220,
                    child: Image.asset(
                      'assets/images/Web/juegos.png',
                      fit: BoxFit.contain,
                      height: 400,
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    left: 160,
                    child: Image.asset(
                      'assets/images/Donarin/12.png',
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            )
          ),
        ],
      ),
    );
  }
  
  Widget _buildOverviewText(BuildContext context, String number, String title, String subtitle) {
    // ... (sin cambios)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: donAppText.withOpacity(0.7),
              ),
            ),
            if (number.isNotEmpty) SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: donAppText,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.only(left: number.isEmpty ? 0 : 48), 
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 18,
              color: donAppText.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHowToDonateSection(BuildContext context) {
    // ... (sin cambios)
    return Container(
      color: Colors.grey.shade100, // <-- FONDO GRIS
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 80),
      child: Column(
        children: [
          Text(
            "¿CÓMO DONAR?",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: donAppText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Donar es un proceso simple y rápido. Te lo mostramos en 4 pasos:",
            style: TextStyle(
              fontSize: 18,
              color: donAppText.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepCard(
                icon: Icons.checklist_rtl,
                title: "1. Responde la Encuesta",
                description: "Completa el formulario de pre-evaluación para verificar que cumples con los requisitos básicos para donar sangre."
              ),
              _StepCard(
                icon: Icons.app_registration,
                title: "2. Agenda tu Hora",
                description: "Selecciona el centro de donación que más te acomode, elige el día y la hora para reservar tu cita."
              ),
              _StepCard(
                icon: Icons.bloodtype,
                title: "3. Asiste y Dona",
                description: "Preséntate en el centro de donación a la hora agendada. El proceso de donación es seguro y dura pocos minutos."
              ),
              _StepCard(
                icon: Icons.workspace_premium,
                title: "4. Gana y Comparte",
                description: "¡Listo! Sumarás puntos, desbloquearás logros y podrás ver cómo tu donación ayuda a la comunidad."
              ),
            ],
          )
        ],
      )
    );
  }

  Widget _StepCard({required IconData icon, required String title, required String description}) {
    // ... (sin cambios)
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Icon(icon, size: 64, color: donAppRed),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: donAppText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: donAppText.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoSection(BuildContext context, String title, String content, {bool isAlternate = false}) {
    // ... (sin cambios)
    return Container(
      color: isAlternate ? Colors.grey.shade100 : Colors.white, // <-- FONDO BLANCO
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: donAppRed.withOpacity(0.8),
              ),
            ),
          ),
          SizedBox(width: 40),
          Expanded(
            flex: 2,
            child: Text(
              content,
              style: TextStyle(
                fontSize: 18,
                color: donAppText,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context) {
    return Container(
      // --- 🌟 CAMBIO: Color de fondo alternado ---
      color: Colors.grey.shade100, // <-- FONDO GRIS
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 80),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            "EQUIPO DONAPP",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: donAppText,
            ),
          ),
          const SizedBox(height: 50),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              _TeamMemberCard(
                imagePath: 'images/Web/Integrantes/gabi.jpg', 
                name: 'Gabriel Leyton', 
                role: 'Product Owner'
              ),
              _TeamMemberCard(
                imagePath: 'images/Web/Integrantes/jose.jpg', 
                name: 'José Manzano', 
                role: 'Scrum Master'
              ),
              _TeamMemberCard(
                imagePath: 'images/Web/Integrantes/manu.jpg', 
                name: 'Manuel Silva', 
                role: 'Encargado de Tecnologías'
              ),
              _TeamMemberCard(
                imagePath: 'images/Web/Integrantes/thomi.jpg', 
                name: 'Thomas Rodriguez', 
                role: 'Encargado de UX/UI'
              ),
              _TeamMemberCard(
                imagePath: 'images/Web/Integrantes/sharon.jpg', 
                name: 'Sharon Andrades', 
                role: 'Encargada de Marketing & Comunicaciones'
              ),
              _TeamMemberCard(
                imagePath: 'images/Web/Integrantes/illanes.jpg', 
                name: 'Vicente Illanes', 
                role: 'Encargado de Testing'
              ),
            ],
          ),
          
          const SizedBox(height: 80), 

          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1000), 
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Image.asset(
                      'assets/images/Donarin/12.png',
                      height: 500,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 60),
                Expanded(
                  flex: 2, 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nuestros valores.",
                        style: TextStyle(
                          fontSize: 36, 
                          fontWeight: FontWeight.bold, 
                          color: donAppRed
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildValueText(
                        "Solidaridad:", 
                        "Cada función de DonApp busca reforzar el espíritu altruista y comunitario que caracteriza la donación voluntaria de sangre."
                      ),
                      _buildValueText(
                        "Innovación con propósito:",
                        "Integramos tecnología, algoritmos, IA y herramientas de gamificación con foco en generar impacto social positivo."
                      ),
                      _buildValueText(
                        "Confianza y transparencia:",
                        "La información entregada al usuario es clara, confiable y validada, para asegurar seguridad y credibilidad en cada interacción."
                      ),
                      _buildValueText(
                        "Comunidad y empatía:",
                        "Promovemos la donación frecuente y sostenida, entendiendo que cada acción dentro de la app contribuye a salvar vidas."
                      ),
                      _buildValueText(
                        "Colaboración:", 
                        "Reconocemos el valor de articular a donantes, instituciones y comunidades para lograr un impacto colectivo mayor."
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueText(String title, String description) {
    // ... (sin cambios)
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: donAppText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 14,
              color: donAppText.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: SECCIÓN DE CONTACTO ---
  Widget _buildContactSection(BuildContext context) {
    // ... (sin cambios)
    return Container(
      color: donAppPeach.withOpacity(0.5), // <-- FONDO MELOCOTÓN
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 80),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            "CONTÁCTANOS",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: donAppText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "¿Tienes dudas o quieres colaborar? ¡Escríbenos!",
            style: TextStyle(
              fontSize: 18,
              color: donAppText.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          
          Wrap(
            spacing: 40, 
            runSpacing: 40, 
            alignment: WrapAlignment.center,
            children: [
              _ContactButton(
                icon: FontAwesomeIcons.envelope, 
                text: "Gmail", 
                url: "mailto:equipo.donapp@gmail.com", 
                color: Colors.red.shade700,
              ),
              _ContactButton(
                icon: FontAwesomeIcons.instagram, 
                text: "Instagram", 
                url: "https://www.instagram.com/donapp.chile/", 
                color: Color(0xFFE1306C), 
              ),
              _ContactButton(
                icon: FontAwesomeIcons.linkedin, 
                text: "LinkedIn", 
                url: "https://www.linkedin.com/company/donapp-chile/", 
                color: Color(0xFF0A66C2), 
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET: BOTÓN DE CONTACTO ---
  Widget _ContactButton({
    required IconData icon, 
    required String text, 
    required String url,
    required Color color,
  }) {
    // ... (sin cambios)
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(16),
      hoverColor: color.withOpacity(0.1),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        width: 220, 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 48, color: color),
            SizedBox(height: 20),
            Text(
              text,
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w600,
                color: donAppText 
              ),
            ),
          ],
        ),
      ),
    );
  }


} // Fin de _GuestInformativePageState


// --- "INTERRUPTOR" Y VISTA 2: DASHBOARD DE MARKETING (HU79A) ---
// (Esta parte no cambia)
class HomeBodyWeb extends StatefulWidget {
  // ... (sin cambios)
  const HomeBodyWeb({super.key});

  @override
  State<HomeBodyWeb> createState() => _HomeBodyWebState();
}
class _HomeBodyWebState extends State<HomeBodyWeb> {
  // ... (sin cambios)
  late final HomeController _controller;
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isLoggedIn = false; 
  late List<Widget> _pages;
  late List<NavigationRailDestination> _navDestinations;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _controller.addListener(_onAuthChange);
    _checkLoginStatusAndSetupUI();
  }

  @override
  void dispose() {
    _controller.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    setState(() {
      _isLoggedIn = _controller.isLoggedIn;
      if (_isLoggedIn) {
        _setupDashboardPages();
        _setupDashboardNav();
      }
    });
  }

  Future<void> _checkLoginStatusAndSetupUI() async {
    await _controller.loadUserData(context);
    _isLoggedIn = _controller.isLoggedIn;

    if (_isLoggedIn) {
      _setupDashboardPages();
      _setupDashboardNav();
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _setupDashboardPages() {
    _pages = [
      HomeDashboardPage(showTrivia: _isLoggedIn && !_controller.isAdmin),
      if (_controller.isAdmin) ...[
        CampaniasScreen(),
        StatsShell(),
        FiltroUsuariosScreen(),
        EncuestaApp(),
      ],
      ChatAsistente(), 
    ];
  }

  void _setupDashboardNav() {
    _navDestinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Inicio'),
      ),
    ];

    if (_controller.isAdmin) {
      _navDestinations.addAll([
        const NavigationRailDestination(
          icon: Icon(Icons.campaign_outlined),
          selectedIcon: Icon(Icons.campaign),
          label: Text('Campañas'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('Estadísticas'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.filter_alt_outlined),
          selectedIcon: Icon(Icons.filter_alt),
          label: Text('Usuarios'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: Text('Encuestas'),
        ),
      ]);
    }

    _navDestinations.add(
      const NavigationRailDestination(
        icon: Icon(Icons.chat_bubble_outline_rounded),
        selectedIcon: Icon(Icons.chat_bubble_rounded),
        label: Text('Chat'),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (!_isLoggedIn) {
      return GuestInformativePage(controller: _controller);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            elevation: 3,
            destinations: _navDestinations,
            selectedIconTheme: const IconThemeData(color: AppColors.customBlue, size: 28),
            unselectedIconTheme: const IconThemeData(color: Colors.black54, size: 26),
          ),
          Expanded(
            flex: 3, 
            child: Column(
              children: [
                HomeHeader(controller: _controller),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
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


// --- WIDGET DE DIÁLOGO-STEPPER (SIN CAMBIOS) ---
class _DonationStepperDialog extends StatefulWidget {
  // ... (sin cambios)
  final bool isGuest;
  const _DonationStepperDialog({this.isGuest = false});

  @override
  State<_DonationStepperDialog> createState() => _DonationStepperDialogState();
}
class _DonationStepperDialogState extends State<_DonationStepperDialog> {
  // ... (sin cambios)
  int _currentStep = 0;
  final Map<String, dynamic> _formData = {};
  String? _failureMessage;

  void _nextStep([Map<String, dynamic>? data]) {
    if (data != null) _formData.addAll(data);
    if (_currentStep < 5) setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _onEligibilityFailure(String message) {
    setState(() {
      _failureMessage = message;
    });
  }

  void _onConfirmationSuccess() {
    Navigator.of(context).pop(); 
  }

  @override
  Widget build(BuildContext context) {
    Widget currentView;

    if (_failureMessage != null) {
      currentView = ElegibilityResult(
        detalle: _failureMessage!,
        isDialog: true,
      );
    } else {
      final steps = [
        IntroStep(onNext: _nextStep),
        EligibilityStep(
          onNext: _nextStep,
          onBack: _previousStep,
          onFailure: _onEligibilityFailure,
        ),
        LocationStep(
          onNext: _nextStep, 
          onBack: _previousStep,
          isGuest: widget.isGuest, 
        ),
        DateTimeStep(onNext: _nextStep, onBack: _previousStep),
        PersonalDataStep(onNext: _nextStep, onBack: _previousStep),
        ConfirmationStep(
          onBack: _previousStep,
          data: _formData,
          onConfirm: _onConfirmationSuccess,
          isGuest: widget.isGuest, 
        ),
      ];
      currentView = steps[_currentStep];
    }
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _failureMessage != null ? "Resultado de Evaluación" : "Agendar Donación – Paso ${_currentStep + 1} de 6",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (_failureMessage == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / 6,
                      color: Colors.redAccent,
                      backgroundColor: Colors.red.shade100,
                    ),
                  ),
                if (_failureMessage != null) const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: currentView,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- WIDGET HELPER PARA LA TARJETA DE MIEMBRO DE EQUIPO ---
// (Esta parte estaba bien)
class _TeamMemberCard extends StatelessWidget {
  final String imagePath;
  final String name;
  final String role;
  
  static const Color donAppRed = Color(0xFFE85C54);
  static const Color donAppText = Color(0xFF333333);

  const _TeamMemberCard({
    required this.imagePath,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          // --- (Estética de la tarjeta de miembro) ---
          SizedBox(
            width: 140, 
            height: 140,
            child: ClipRRect( 
              borderRadius: BorderRadius.circular(20), 
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover, 
                errorBuilder: (context, error, stackTrace) {
                  print("Error cargando imagen: $imagePath");
                  return Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.person, size: 70, color: Colors.grey.shade400)
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: donAppRed,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: TextStyle(
              fontSize: 14,
              color: donAppText.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}