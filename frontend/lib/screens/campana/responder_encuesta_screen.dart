import 'package:flutter/material.dart';
import 'api_service.dart';

class ResponderEncuestaScreen extends StatefulWidget {
  final Map<String, dynamic> encuesta;
  const ResponderEncuestaScreen({super.key, required this.encuesta});

  @override
  State<ResponderEncuestaScreen> createState() => _ResponderEncuestaScreenState();
}

class _ResponderEncuestaScreenState extends State<ResponderEncuestaScreen> {
  // ---------------------------------------------------------------------------
  // Form y estado local:
  // ---------------------------------------------------------------------------
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> respuestas = {};
  bool _enviando = false;

  // Datos del usuario para validar criterios (solo front)
  final _edadCtrl = TextEditingController();
  final _comunaCtrl = TextEditingController();

  // Si tienes auth real, reemplaza por el ID del usuario autenticado.
  int? _userId = 1; // TODO: cámbialo por el real o déjalo en null para anónimo

  @override
  void dispose() {
    _edadCtrl.dispose();
    _comunaCtrl.dispose();
    super.dispose();
  }

  // ------------------- Helpers de criterios (front-only) -------------------
  int? get _critEdadMin => _asInt(widget.encuesta['edadMin']);
  int? get _critEdadMax => _asInt(widget.encuesta['edadMax']);

  // Puede venir como string ("Ñuñoa") o lista de strings (["Ñuñoa","Santiago"])
  List<String> get _critUbicaciones {
    final u1 = widget.encuesta['ubicacion'];
    final uN = widget.encuesta['ubicaciones']; // opcional si lo usas
    final out = <String>[];
    if (u1 is String && u1.trim().isNotEmpty) out.add(u1.trim());
    if (uN is List) {
      for (final e in uN) {
        if (e is String && e.trim().isNotEmpty) out.add(e.trim());
      }
    }
    return out.map((e) => e.toLowerCase()).toList();
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  int? get _edadUsuario => int.tryParse(_edadCtrl.text.trim());
  String get _comunaUsuario => _comunaCtrl.text.trim();

  bool get _cumpleEdad {
    final e = _edadUsuario;
    if (e == null) return false; // pedimos la edad siempre
    final min = _critEdadMin;
    final max = _critEdadMax;
    if (min != null && e < min) return false;
    if (max != null && e > max) return false;
    // además validamos rango general de sentido común:
    if (e < 18 || e > 100) return false;
    return true;
  }

  bool get _cumpleUbicacion {
    final reqs = _critUbicaciones;
    if (reqs.isEmpty) return true; // si no hay criterio, se ignora
    if (_comunaUsuario.isEmpty) return false;
    return reqs.contains(_comunaUsuario.toLowerCase());
  }

  List<String> get _motivosNoElegible {
    final m = <String>[];
    if (!_cumpleEdad) {
      final min = _critEdadMin;
      final max = _critEdadMax;
      if (_edadUsuario == null) {
        m.add('Ingresa tu edad');
      } else {
        if (min != null && _edadUsuario! < min) m.add('Edad menor a $min');
        if (max != null && _edadUsuario! > max) m.add('Edad mayor a $max');
        if (_edadUsuario! < 18 || _edadUsuario! > 100) m.add('Edad fuera de 18–100');
      }
    }
    if (!_cumpleUbicacion) {
      m.add(_comunaUsuario.isEmpty
          ? 'Ingresa tu comuna'
          : 'Tu comuna no está dentro del criterio');
    }
    return m;
  }

  bool get _elegible => _cumpleEdad && _cumpleUbicacion;

  // ------------------- Envío -------------------
  Future<void> _enviarRespuestas() async {
    // Validación de preguntas
    final preguntasOk = _formKey.currentState!.validate();
    if (!preguntasOk) return;

    // Validación de criterios (front-only)
    if (!_elegible) {
      final razones = _motivosNoElegible.join(' · ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ No cumples criterios: $razones')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _enviando = true);

    final payload = {
      "survey": widget.encuesta["id"],
      "data": {
        "answers": respuestas,
        "meta": {
          "edad": _edadUsuario,
          "comuna": _comunaUsuario,
        },
        "user": _userId,  // puedes guardarlo también dentro de data
      }
    };

    try {
      await ApiService.postResponse(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Respuestas enviadas")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Error al enviar respuestas")),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Datos de la encuesta
    final String titulo = widget.encuesta["title"] ?? "Encuesta";
    final String descripcion = widget.encuesta["description"] ?? "";
    final List<String> preguntas = (widget.encuesta["questions"] as List<dynamic>)
        .map((e) => e.toString())
        .toList();

    // Criterios (solo para mostrar resumen al usuario)
    final min = _critEdadMin;
    final max = _critEdadMax;
    final ubic = _critUbicaciones;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ Fondo
      appBar: AppBar(
        title: const Text("Responder Encuesta"),
        backgroundColor: theme.scaffoldBackgroundColor, // ✅ Fondo
        foregroundColor: colorScheme.onBackground, // ✅ Color de íconos/texto
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ---------- Cabecera ----------
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: colorScheme.primary, // ✅ Adaptar color
                ),
              ),
              if (descripcion.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(descripcion), // ✅ Color se hereda (onSurface)
              ],

              const SizedBox(height: 16),

              // ---------- Tus datos (para validar criterios) ----------
              Card(
                elevation: 2,
                color: colorScheme.surface, // ✅ Adaptar color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tus datos", style: TextStyle(fontWeight: FontWeight.bold)), // ✅ Color se hereda
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _edadCtrl,
                              decoration: const InputDecoration(
                                labelText: "Tu edad",
                                hintText: "Ej: 25",
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final n = int.tryParse((v ?? '').trim());
                                if (n == null) return 'Ingresa tu edad';
                                if (n < 18 || n > 100) return 'Debe estar entre 18 y 100';
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _comunaCtrl,
                              decoration: InputDecoration(
                                labelText: "Tu comuna",
                                hintText: ubic.isEmpty ? "Ej: Ñuñoa" : "Ej: ${ubic.first}",
                              ),
                              onChanged: (_) => setState(() {}),
                              // Si la encuesta exige ubicación, lo pedimos; si no, lo dejamos opcional
                              validator: (v) {
                                if (_critUbicaciones.isEmpty) return null;
                                return (v == null || v.trim().isEmpty)
                                    ? 'Ingresa tu comuna'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Estado de elegibilidad
                      Row(
                        children: [
                          Icon(
                            _elegible ? Icons.verified : Icons.error_outline,
                            color: _elegible ? colorScheme.secondary : colorScheme.error, // ✅ Adaptar color
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _elegible
                                  ? 'Cumples los criterios para responder.'
                                  : 'No cumples los criterios: ${_motivosNoElegible.join(" · ")}',
                              style: TextStyle(
                                color: _elegible ? colorScheme.secondary : colorScheme.error, // ✅ Adaptar color
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // ✅ Adaptar colores de Chips
                          if (min != null) Chip(label: Text('Edad ≥ $min'), backgroundColor: colorScheme.surfaceVariant),
                          if (max != null) Chip(label: Text('Edad ≤ $max'), backgroundColor: colorScheme.surfaceVariant),
                          if (ubic.isNotEmpty)
                            Chip(label: Text('Comunas: ${ubic.join(", ")}'), backgroundColor: colorScheme.surfaceVariant),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------- Campos de preguntas ----------
              ...preguntas.map((pregunta) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  color: colorScheme.surface, // ✅ Adaptar color
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: pregunta,
                        labelStyle: TextStyle(
                            color: colorScheme.primary // ✅ Adaptar color
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.secondary, width: 2), // ✅ Adaptar color
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      onSaved: (val) => respuestas[pregunta] = val?.trim() ?? "",
                      validator: (val) =>
                          (val == null || val.trim().isEmpty)
                              ? "Por favor responde esta pregunta"
                              : null,
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // ---------- Botón de envío ----------
              ElevatedButton.icon(
                icon: _enviando
                    ? SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary), // ✅ Adaptar color
                      )
                    : const Icon(Icons.send),
                label: Text(_enviando ? "Enviando..." : "Enviar Respuestas"),
                // Solo permitimos envío si es elegible y el formulario está correcto
                onPressed: _enviando ? null : _enviarRespuestas,
                // ✅ Los estilos se heredan del ElevatedButtonThemeData (primary/onPrimary)
              ),
            ],
          ),
        ),
      ),
    );
  }
}