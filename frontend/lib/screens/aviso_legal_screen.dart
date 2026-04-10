import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

// Paleta DonApp
import 'package:donapp_android/colours/app_colors.dart';

class AvisoLegalScreen extends StatefulWidget {
  final bool showAcceptButton;
  const AvisoLegalScreen({Key? key, this.showAcceptButton = false}) : super(key: key);

  @override
  State<AvisoLegalScreen> createState() => _AvisoLegalScreenState();
}

class _AvisoLegalScreenState extends State<AvisoLegalScreen> {
  Map<String, dynamic>? avisoLegalData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvisoLegal();
  }

  Future<void> _loadAvisoLegal() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/Registro/aviso_legal.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      if (!mounted) return;
      setState(() {
        avisoLegalData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error al cargar el aviso legal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. Obtenemos el tema y el esquema de color ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
        foregroundColor: colorScheme.onBackground, // <-- Cambio
        titleSpacing: 0,
        title: Row(
          children: [
            // Ícono
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface, // <-- Cambio
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    color: theme.shadowColor.withOpacity(0.06), // <-- Cambio
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/images/icon.png', fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                "Aviso Legal",
                overflow: TextOverflow.ellipsis, // evita desborde horizontal
                style: TextStyle(
                  color: colorScheme.onBackground, // <-- Cambio
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (avisoLegalData == null)
              ? _EmptyState() // <-- _EmptyState ahora usará el Theme.of(context)
              : _buildAvisoLegalContent(context, theme, colorScheme), // <-- Pasamos el tema
    );
  }

  Widget _buildAvisoLegalContent(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final data = avisoLegalData!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  decoration: _cardDecor(theme, colorScheme), // <-- Pasamos el tema
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DefaultTextStyle(
                      // --- 2. Cambiamos el color de texto por defecto dentro de la tarjeta ---
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: colorScheme.onSurface, // <-- Cambio
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado de la card
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  // Mantenemos el azul personalizado, es intencional
                                  color: AppColors.customBlue[50], 
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.policy_rounded,
                                    color: AppColors.customBlue[700], size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _zw(data['titulo'] ?? 'Información legal y de tratamiento de datos'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    // Mantenemos el azul, es intencional
                                    color: AppColors.customBlue[700], 
                                    letterSpacing: .2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Los widgets _Paragraph, _InfoRow, etc., usarán el Theme.of(context)
                          // por su cuenta o heredarán el DefaultTextStyle
                          const _SectionTitleBlue('Responsable del Tratamiento de Datos'),
                          _buildResponsableInfo(data['responsable']),
                          const SizedBox(height: 16),

                          const _SectionTitleBlue('Finalidades del Tratamiento'),
                          _buildBulletedList(data['finalidades']),
                          const SizedBox(height: 16),

                          const _SectionTitleBlue('Datos Recolectados'),
                          _buildBulletedList(data['datos_recolectados']),
                          const SizedBox(height: 16),

                          const _SectionTitleBlue('Terceros'),
                          _buildBulletedList(data['terceros']),
                          const SizedBox(height: 16),

                          const _SectionTitleBlue('Derechos de los Usuarios'),
                          _buildBulletedList(data['derechos_usuarios']),
                          const SizedBox(height: 16),

                          const _SectionTitleBlue('Almacenamiento y Seguridad'),
                          _Paragraph(_zw(data['almacenamiento_seguridad'] ?? '')),
                          const SizedBox(height: 16),

                          const _SectionTitleBlue('Consentimiento'),
                          _Paragraph(_zw(data['consentimiento'] ?? '')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // CTA (opcional)
            if (widget.showAcceptButton) ...[
              const SizedBox(height: 16),
              _buildAcceptButton(context, colorScheme), // <-- Pasamos colorScheme
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponsableInfo(Map<String, dynamic>? responsable) {
    if (responsable == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(label: 'Nombre:', value: _zw('${responsable['nombre_organizacion'] ?? ''}')),
        _InfoRow(label: 'Dirección:', value: _zw('${responsable['domicilio'] ?? ''}')),
        _InfoRow(label: 'Correo:', value: _zw('${responsable['correo_contacto'] ?? ''}')),
      ],
    );
  }

  Widget _buildBulletedList(List<dynamic>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final text = _zw(item is String ? item : item.toString());
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bullet visual (mantenemos el azul)
              Container(
                margin: const EdgeInsets.only(top: 7),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.customBlue[700],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _Paragraph(text)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAcceptButton(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('acceptedPolicy', true);
          await prefs.setBool('hasLaunchedOnce', true);
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        },
        // --- 3. Adaptamos el botón ---
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary, // <-- Cambio (o puedes dejar AppColors.customBlue[700] si es intencional)
          foregroundColor: colorScheme.onPrimary, // <-- Cambio
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          "Aceptar y Continuar",
          style: TextStyle(
            fontSize: 16,
            // color: AppColors.white, // <-- Eliminado (lo maneja foregroundColor)
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/* ──────────────── Widgets auxiliares ──────────────── */

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    // --- 4. Hacemos que el párrafo se adapte ---
    final colorScheme = Theme.of(context).colorScheme; 
    
    return SelectableText(
      text,
      maxLines: null,
      scrollPhysics: const NeverScrollableScrollPhysics(),
      style: TextStyle(
        fontSize: 14,
        height: 1.55,
        color: colorScheme.onSurface, // <-- Cambio
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // --- 5. Hacemos que el estado vacío se adapte ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: _cardDecor(theme, colorScheme), // <-- Pasamos el tema
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.customBlue[50], // Mantenemos azul
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.info_rounded, color: AppColors.customBlue[700], size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "No se pudo cargar el aviso legal.",
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface), // <-- Cambio
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitleBlue extends StatelessWidget {
  final String text;
  const _SectionTitleBlue(this.text);

  @override
  Widget build(BuildContext context) {
    // Este widget se llama "Blue", así que dejamos el color azul intencionalmente
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.customBlue[700],
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    // --- 6. Hacemos que InfoRow se adapte ---
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heredará el color del DefaultTextStyle
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          // 👇 Flexible + SelectableText con quiebres seguros
          Expanded(
            child: SelectableText(
              value,
              maxLines: null,
              style: TextStyle(color: colorScheme.onSurface), // <-- Cambio
            ),
          ),
        ],
      ),
    );
  }
}

/* ──────────────── Estilos reutilizables ──────────────── */

// --- 7. Hacemos que _cardDecor se adapte ---
BoxDecoration _cardDecor(ThemeData theme, ColorScheme colorScheme) {
  return BoxDecoration(
    color: colorScheme.surface, // <-- Cambio
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: colorScheme.outline.withOpacity(0.5)), // <-- Cambio
    boxShadow: [
      BoxShadow(
        color: theme.shadowColor.withOpacity(0.06), // <-- Cambio
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/* ──────────────── Util: quiebre seguro para strings largos ──────────────── */

/// Inserta espacios de ancho cero tras separadores comunes para que Text pueda
/// cortar líneas sin overflow (ideal para correos, URLs, tokens largos).
String _zw(String input) {
  if (input.isEmpty) return input;
  const zws = '\u200B';
  final buf = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    final ch = input[i];
    buf.write(ch);
    if (ch == '/' || ch == '.' || ch == '_' || ch == '-' || ch == '@' || ch == ':') {
      buf.write(zws);
    }
  }
  return buf.toString();
}