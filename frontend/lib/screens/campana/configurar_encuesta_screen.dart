import 'package:donapp_android/screens/campana/seleccionar_encuesta_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, FilteringTextInputFormatter;
import 'package:excel/excel.dart';

import 'api_service.dart';
import 'responder_encuesta_screen.dart';
import 'ver_respuestas_screen.dart';

/// ============================================================================
/// MODELO + LECTOR DE EXCEL
/// ... (Clase Ubicacion sin cambios, ya que no maneja UI)
/// ============================================================================
class Ubicacion {
  final String region;
  final String provincia;
  final String comuna;

  const Ubicacion({required this.region, required this.provincia, required this.comuna});

  // Acceso seguro a celdas: convierte a String y hace trim
  static String _cell(List<Data?> row, int i) {
    if (i >= row.length) return '';
    final v = row[i]?.value;
    return v == null ? '' : v.toString().trim();
  }

  // Detecta si la fila parece encabezado
  static bool _isHeaderRow(List<Data?> row) {
    final c0 = _cell(row, 0).toLowerCase();
    final c1 = _cell(row, 1).toLowerCase();
    final c2 = _cell(row, 2).toLowerCase();
    return c0.contains('comuna') &&
           c1.contains('provinc') &&
           (c2.contains('región') || c2.contains('region'));
  }

  /// Carga y parsea el Excel. Lanza Exception con mensaje claro si no hay datos válidos.
  static Future<List<Ubicacion>> cargarDesdeExcel({String assetPath = 'assets/ubicaciones.xlsx'}) async {
    final data  = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final excel = Excel.decodeBytes(bytes);

    final ubicaciones = <Ubicacion>[];

    for (final entry in excel.tables.entries) {
      final sheet = entry.value;
      final rows  = sheet.rows;
      if (rows.isEmpty) continue;

      final start = _isHeaderRow(rows.first) ? 1 : 0;
      for (var i = start; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 3) continue; // garantiza [0],[1],[2]

        final comuna    = _cell(row, 0);
        final provincia = _cell(row, 1);
        final region    = _cell(row, 2);

        if (comuna.isEmpty || provincia.isEmpty || region.isEmpty) continue;

        ubicaciones.add(Ubicacion(region: region, provincia: provincia, comuna: comuna));
      }
    }

    if (ubicaciones.isEmpty) {
      throw Exception(
        'No se encontraron ubicaciones válidas en $assetPath.\n'
        'Verifica que tenga columnas Comuna / Provincia / Región (en ese orden).',
      );
    }
    return ubicaciones;
  }
}

/// ============================================================================
/// PANTALLA: CONFIGURAR ENCUESTA
/// ============================================================================
class ConfigurarEncuestaScreen extends StatefulWidget {
  final Map<String, dynamic> encuesta;
  const ConfigurarEncuestaScreen({super.key, required this.encuesta});

  @override
  State<ConfigurarEncuestaScreen> createState() => _ConfigurarEncuestaScreenState();
}

class _ConfigurarEncuestaScreenState extends State<ConfigurarEncuestaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Edad
  final _edadMinCtrl = TextEditingController();
  final _edadMaxCtrl = TextEditingController();

  // Cascada región→provincia→comuna
  late Future<void> _futureCargaUbicaciones;
  List<Ubicacion> _todas = [];
  List<String> _regiones = [];
  List<String> _provincias = [];
  List<String> _comunas = [];

  String? _regionSel;
  String? _provSel;
  String? _comunaSel;

  // Canales
  bool correo = false;
  bool push = false;
  bool whatsapp = false;
  String? _errorCanales;

  // Estado
  bool _guardando = false;
  Object? _excelError; // para mostrar error de lectura si ocurre

  @override
  void initState() {
    super.initState();
    _futureCargaUbicaciones = _cargarUbicaciones();
    _edadMinCtrl.addListener(_refresh);
    _edadMaxCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _edadMinCtrl.dispose();
    _edadMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarUbicaciones() async {
    setState(() {
      _excelError = null;
    });
    try {
      _todas = await Ubicacion.cargarDesdeExcel();

      // Regiones únicas ordenadas
      final setRegiones = <String>{};
      for (final u in _todas) {
        if (u.region.isNotEmpty) setRegiones.add(u.region);
      }
      _regiones = setRegiones.toList()..sort();

      // Al inicio: provincias/comunas vacías
      _provincias = [];
      _comunas = [];
    } catch (e) {
      _excelError = e;
    } finally {
      if (mounted) setState(() {});
    }
  }

  void _onRegionChanged(String? region) {
    setState(() {
      _regionSel = region;
      _provSel = null;
      _comunaSel = null;

      final setProv = <String>{};
      for (final u in _todas.where((x) => x.region == _regionSel)) {
        if (u.provincia.isNotEmpty) setProv.add(u.provincia);
      }
      _provincias = setProv.toList()..sort();
      _comunas = [];
    });
  }

  void _onProvinciaChanged(String? provincia) {
    setState(() {
      _provSel = provincia;
      _comunaSel = null;

      final setCom = <String>{};
      for (final u in _todas.where((x) => x.region == _regionSel && x.provincia == _provSel)) {
        if (u.comuna.isNotEmpty) setCom.add(u.comuna);
      }
      _comunas = setCom.toList()..sort();
    });
  }

  void _onComunaChanged(String? comuna) => setState(() => _comunaSel = comuna);

  // ---------------- VALIDACIONES UI ----------------
  String? _valEdadMin(String? v) {
    if (v == null || v.isEmpty) return 'Requerido';
    final n = int.tryParse(v);
    if (n == null) return 'Solo números';
    if (n < 18 || n > 100) return 'Entre 18 y 100';
    final maxVal = int.tryParse(_edadMaxCtrl.text);
    if (maxVal != null && n > maxVal) return 'No puede ser mayor que máx.';
    return null;
  }

  String? _valEdadMax(String? v) {
    if (v == null || v.isEmpty) return 'Requerido';
    final n = int.tryParse(v);
    if (n == null) return 'Solo números';
    if (n < 18 || n > 100) return 'Entre 18 y 100';
    final minVal = int.tryParse(_edadMinCtrl.text);
    if (minVal != null && n < minVal) return 'No puede ser menor que mín.';
    return null;
  }

  String? _valRegion(String? v) => (v == null || v.isEmpty) ? 'Selecciona una región' : null;
  String? _valProv(String? v)   => (v == null || v.isEmpty) ? 'Selecciona una provincia' : null;
  String? _valComuna(String? v) => (v == null || v.isEmpty) ? 'Selecciona una comuna' : null;

  bool get _alMenosUnCanal => correo || push || whatsapp;

  bool get _formOK {
    final eMin = _valEdadMin(_edadMinCtrl.text);
    final eMax = _valEdadMax(_edadMaxCtrl.text);
    final rOk = _valRegion(_regionSel) == null;
    final pOk = _valProv(_provSel) == null;
    final cOk = _valComuna(_comunaSel) == null;
    final canalesOk = _alMenosUnCanal;
    return eMin == null && eMax == null && rOk && pOk && cOk && canalesOk && !_guardando;
  }

  void _refresh() => setState(() {});

  Future<void> _guardarConfiguracion() async {
    final valido = _formKey.currentState!.validate();
    setState(() => _errorCanales = _alMenosUnCanal ? null : 'Selecciona al menos un canal');
    if (!valido || !_alMenosUnCanal) return;

    setState(() => _guardando = true);
    try {
      await ApiService.patchSegmentacion(widget.encuesta["id"], {
        "edadMin": int.tryParse(_edadMinCtrl.text),
        "edadMax": int.tryParse(_edadMaxCtrl.text),
        "ubicacion": _comunaSel, // compatible con tu API actual
        // Si luego tu API acepta separados, puedes incluir:
        // "region": _regionSel,
        // "provincia": _provSel,
        // "comuna": _comunaSel,
      });

      await ApiService.patchCanales(widget.encuesta["id"], [
        if (correo) "correo",
        if (push) "push",
        if (whatsapp) "whatsapp",
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Configuración guardada")),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Error guardando configuración")),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final encuesta = widget.encuesta;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ Fondo
      appBar: AppBar(
        title: Text("Configurar: ${encuesta["title"]}"),
        backgroundColor: theme.scaffoldBackgroundColor, // ✅ Fondo
        foregroundColor: colorScheme.onBackground, // ✅ Color de íconos/texto
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- SEGMENTACIÓN ----------------
              Text(
                "Segmentación",
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary), // ✅ Adaptar color
              ),
              TextFormField(
                controller: _edadMinCtrl,
                decoration: const InputDecoration(labelText: "Edad mínima"),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _valEdadMin,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _edadMaxCtrl,
                decoration: const InputDecoration(labelText: "Edad máxima"),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _valEdadMax,
              ),
              const SizedBox(height: 12),

              // ---------------- CASCADA R→P→C + manejo de error Excel ----------------
              FutureBuilder<void>(
                future: _futureCargaUbicaciones,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    );
                  }
                  if (_excelError != null) {
                    return Card(
                      color: colorScheme.errorContainer, // ✅ Adaptar color
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "No se pudo leer el Excel.",
                              style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.bold), // ✅ Adaptar color
                            ),
                            const SizedBox(height: 8),
                            Text(_excelError.toString(), style: TextStyle(color: colorScheme.onErrorContainer)), // ✅ Adaptar color
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _futureCargaUbicaciones = _cargarUbicaciones();
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text("Reintentar"),
                                style: TextButton.styleFrom(
                                  foregroundColor: colorScheme.onErrorContainer, // ✅ Adaptar color
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Región"),
                        isExpanded: true,
                        value: _regionSel,
                        dropdownColor: colorScheme.surface, // ✅ Color del menú
                        items: _regiones
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: _onRegionChanged,
                        validator: _valRegion,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Provincia"),
                        isExpanded: true,
                        value: _provSel,
                        dropdownColor: colorScheme.surface, // ✅ Color del menú
                        items: _provincias
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (_regionSel == null) ? null : _onProvinciaChanged,
                        validator: _valProv,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Comuna"),
                        isExpanded: true,
                        value: _comunaSel,
                        dropdownColor: colorScheme.surface, // ✅ Color del menú
                        items: _comunas
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (_provSel == null) ? null : _onComunaChanged,
                        validator: _valComuna,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // ---------------- CANALES ----------------
              Text(
                "Canales de distribución",
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary), // ✅ Adaptar color
              ),
              Column(
                children: [
                  CheckboxListTile(
                    value: correo,
                    onChanged: (v) => setState(() => correo = v ?? false),
                    title: const Text("Correo electrónico"),
                    contentPadding: EdgeInsets.zero,
                    activeColor: colorScheme.primary, // ✅ Adaptar color
                  ),
                  CheckboxListTile(
                    value: push,
                    onChanged: (v) => setState(() => push = v ?? false),
                    title: const Text("Notificaciones Push"),
                    contentPadding: EdgeInsets.zero,
                    activeColor: colorScheme.primary, // ✅ Adaptar color
                  ),
                  CheckboxListTile(
                    value: whatsapp,
                    onChanged: (v) => setState(() => whatsapp = v ?? false),
                    title: const Text("WhatsApp"),
                    contentPadding: EdgeInsets.zero,
                    activeColor: colorScheme.primary, // ✅ Adaptar color
                  ),
                  if (_errorCanales != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          _errorCanales!,
                          style: TextStyle(color: colorScheme.error, fontSize: 12), // ✅ Adaptar color
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------------- RESUMEN VISUAL ----------------
              Card(
                elevation: 2,
                color: colorScheme.surface, // ✅ Adaptar color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // ✅ Adaptar Chips para que usen SurfaceVariant
                      if (_edadMinCtrl.text.isNotEmpty) Chip(label: Text('Edad ≥ ${_edadMinCtrl.text}'), backgroundColor: colorScheme.surfaceVariant),
                      if (_edadMaxCtrl.text.isNotEmpty) Chip(label: Text('Edad ≤ ${_edadMaxCtrl.text}'), backgroundColor: colorScheme.surfaceVariant),
                      if (_regionSel != null) Chip(label: Text(_regionSel!), backgroundColor: colorScheme.surfaceVariant),
                      if (_provSel != null) Chip(label: Text(_provSel!), backgroundColor: colorScheme.surfaceVariant),
                      if (_comunaSel != null) Chip(label: Text(_comunaSel!), backgroundColor: colorScheme.surfaceVariant),
                      if (correo) Chip(label: const Text('Correo'), backgroundColor: colorScheme.surfaceVariant),
                      if (push) Chip(label: const Text('Push'), backgroundColor: colorScheme.surfaceVariant),
                      if (whatsapp) Chip(label: const Text('WhatsApp'), backgroundColor: colorScheme.surfaceVariant),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- GUARDAR ----------------
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _guardando
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary)) // ✅ Adaptar color
                          : const Icon(Icons.save),
                      label: Text(_guardando ? "Guardando..." : "Guardar Configuración"),
                      onPressed: _formOK ? _guardarConfiguracion : null,
                      // ✅ Los estilos se heredan del ElevatedButtonThemeData (primary/onPrimary)
                    ),
                  ),
                ],
              ),

              const Divider(height: 40),

              // ---------------- ACCIONES ----------------
              Text(
                "Acciones",
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary), // ✅ Adaptar color
              ),
              const SizedBox(height: 8),
              // Estos botones ya deberían usar el estilo del ElevatedButton del tema.
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_note),
                label: const Text("Responder Encuesta"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeleccionarEncuestaScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text("Ver Respuestas"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerRespuestasScreen(encuesta: encuesta),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}