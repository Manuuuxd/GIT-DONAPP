import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PoliticaPrivacidadScreen extends StatefulWidget {
  final bool showContinue;

  const PoliticaPrivacidadScreen({
    super.key,
    this.showContinue = false,
  });

  @override
  State<PoliticaPrivacidadScreen> createState() =>
      _PoliticaPrivacidadScreenState();
}

class _PoliticaPrivacidadScreenState extends State<PoliticaPrivacidadScreen> {
  String markdownContent = "";

  @override
  void initState() {
    super.initState();
    loadMarkdown();
  }

  Future<void> loadMarkdown() async {
    try {
      final content =
          await rootBundle.loadString('assets/politica_privacidad_donapp.md');
      if (!mounted) return;
      setState(() => markdownContent = content);
    } catch (e) {
      if (!mounted) return;
      setState(
          () => markdownContent = 'Error al cargar la Política de Privacidad.');
    }
  }

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('authToken');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. Obtenemos el tema y el esquema de color ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Header: ícono + títulos
            Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface, // <-- Cambio
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        color: theme.shadowColor.withOpacity(0.08), // <-- Cambio
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/icon.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "DonApp",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onBackground), // <-- Cambio
                ),
                const SizedBox(height: 12),
                Text(
                  "Política de Privacidad",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onBackground), // <-- Cambio
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Contenido markdown
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: 3.5,
                  // --- 2. Hacemos que la tarjeta respete el tema ---
                  color: colorScheme.surface, // <-- Cambio
                  shadowColor: theme.shadowColor, // <-- Cambio
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: markdownContent.isEmpty
                        ? Center(
                            child: CircularProgressIndicator(
                            color: colorScheme.primary, // <-- Cambio (opcional)
                          ))
                        : Markdown(
                            data: markdownContent,
                            physics: const BouncingScrollPhysics(),
                            // --- 3. Hacemos que el texto del Markdown respete el tema ---
                            styleSheet: MarkdownStyleSheet(
                              h1: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface), // <-- Cambio
                              h2: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface), // <-- Cambio
                              h3: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface), // <-- Cambio
                              p: TextStyle(
                                  fontSize: 14,
                                  height: 1.55,
                                  color: colorScheme.onSurface), // <-- Cambio
                              listBullet: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface), // <-- Cambio
                              a: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: colorScheme.primary), // <-- Cambio
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // Botón aceptar / continuar
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // --- 4. Hacemos que el botón respete el tema ---
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary, // <-- Cambio
                    foregroundColor: colorScheme.onPrimary, // <-- Cambio (Color del texto)
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final bool isLoggedIn = await _checkLoginStatus();
                    if (!mounted) return;

                    if (isLoggedIn) {
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Text(
                    widget.showContinue
                        ? "Aceptar y Continuar"
                        : "Aceptar y Continuar",
                    // --- 5. El color del texto ahora se hereda del foregroundColor ---
                    style: const TextStyle(
                        fontSize: 16,
                        // color: Colors.white, // <-- Eliminado
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}