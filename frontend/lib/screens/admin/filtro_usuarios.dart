import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:donapp_android/screens/Usuario/user_model.dart';
import 'package:donapp_android/screens/admin/get_usuarios.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:donapp_android/screens/ubicaciones.dart';
import 'package:donapp_android/screens/formatFecha.dart';

class FiltroUsuariosScreen extends StatefulWidget {
  const FiltroUsuariosScreen({super.key});

  @override
  State createState() => _FiltroUsuariosScreenState();
}

class _FiltroUsuariosScreenState extends State<FiltroUsuariosScreen> {
  String? sexoSeleccionado;          // 'M' | 'F' | 'O'
  bool? aptoParaDonar;               // elegible=true/false
  String? tipoSangreSeleccionado;    // 'O+' etc
  DateTime? fechaDesde;
  DateTime? fechaHasta;
  String? comunaBusqueda;
  String? regionBusqueda;
  String? provinciaBusqueda;

  List<Ubicacion> todasUbicaciones = [];

  // ---- soporte para autorrelleno desde RouteSettings.arguments ----
  bool _aplicadoInicial = false;
  bool _ubicacionesCargadas = false;
  Map<String, dynamic>? _pendingArgs;

  @override
  void initState() {
    super.initState();
    Ubicacion('', '', '').cargarUbicaciones().then((data) {
      setState(() {
        todasUbicaciones = data;
        _ubicacionesCargadas = true;
      });
      // si ya tenemos args pendientes, aplicarlos ahora
      if (_pendingArgs != null && !_aplicadoInicial) {
        _aplicarAutorrelleno(_pendingArgs!);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final argsRaw = ModalRoute.of(context)?.settings.arguments;
    if (argsRaw is Map) {
      // cast seguro
      final args = Map<String, dynamic>.from(argsRaw as Map);
      _pendingArgs = args;
      // si ya están cargadas las ubicaciones, aplicamos de una
      if (_ubicacionesCargadas && !_aplicadoInicial) {
        _aplicarAutorrelleno(args);
      }
    }
  }

  DateTime? _parseFecha(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    // intenta parsear ISO o YYYY-MM-DD
    try {
      return DateTime.tryParse(s);
    } catch (_) {
      return null;
    }
  }

  bool? _parseBoolLoose(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'si' || s == 'sí' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  void _aplicarAutorrelleno(Map<String, dynamic> q) {
    if (_aplicadoInicial) return;

    // --- sangre ---
    final gs = (q['grupo_sanguineo'] ?? q['grupo'] ?? q['grupo_sangre'])?.toString();
    // normaliza p.e. "o +" -> "O+"
    String? gsNorm;
    if (gs != null && gs.trim().isNotEmpty) {
      final t = gs.replaceAll(' ', '').toUpperCase();
      final valid = {'A+','A-','B+','B-','AB+','AB-','O+','O-'};
      gsNorm = valid.contains(t) ? t : null;
    }

    // --- elegible / estado ---
    // del backend puede venir "elegible": true/false o "estado": "activo"/"inactivo"
    bool? elegible = _parseBoolLoose(q['elegible']);
    final estado = (q['estado'] ?? '').toString().toLowerCase();
    if (elegible == null && (estado == 'activo' || estado == 'inactivo')) {
      // no todos los sistemas equiparan "activo" con elegible, pero si quieres:
      // activo -> null (no fijes), o asume true si tu dominio lo usa así:
      // elegible = (estado == 'activo');
    }

    // --- fechas ---
    final fDesde = _parseFecha(q['ultima_donacion_desde']);
    final fHasta = _parseFecha(q['ultima_donacion_hasta']);

    // --- sexo (opcional) ---
    final sexo = (q['sexo'] ?? q['genero'])?.toString().toUpperCase();
    String? sexoNorm;
    if (sexo != null && sexo.isNotEmpty) {
      if (['M','F','O'].contains(sexo)) sexoNorm = sexo;
      if (['MASCULINO','HOMBRE'].contains(sexo)) sexoNorm = 'M';
      if (['FEMENINO','MUJER'].contains(sexo)) sexoNorm = 'F';
      if (['OTRO','X','NB','NO BINARIO'].contains(sexo)) sexoNorm = 'O';
    }

    // --- ubicaciones ---
    final comuna = (q['comuna'] ?? '').toString();
    final region = (q['region'] ?? '').toString();
    final provincia = (q['provincia'] ?? '').toString();

    setState(() {
      // set simples
      if (gsNorm != null) tipoSangreSeleccionado = gsNorm;
      if (elegible != null) aptoParaDonar = elegible;
      if (fDesde != null) fechaDesde = fDesde;
      if (fHasta != null) fechaHasta = fHasta;
      if (sexoNorm != null) sexoSeleccionado = sexoNorm;

      // set de ubicaciones (respetando jerarquía)
      if (region.isNotEmpty) regionBusqueda = region;
      if (provincia.isNotEmpty) provinciaBusqueda = provincia;
      if (comuna.isNotEmpty) comunaBusqueda = comuna;

      // si no vino provincia/comuna pero sí comuna, intentamos inferir
      if (comunaBusqueda != null && (regionBusqueda == null || provinciaBusqueda == null)) {
        final hit = todasUbicaciones.firstWhere(
          (u) => u.comuna.toLowerCase() == comunaBusqueda!.toLowerCase(),
          orElse: () => Ubicacion('', '', ''),
        );
        if (hit.region.isNotEmpty) regionBusqueda = hit.region;
        if (hit.provincia.isNotEmpty) provinciaBusqueda = hit.provincia;
      }

      _aplicadoInicial = true;
    });

    debugPrint('🧪 filtros iniciales aplicados -> '
        'sexo=$sexoSeleccionado, elegible=$aptoParaDonar, grupo=$tipoSangreSeleccionado, '
        'desde=$fechaDesde, hasta=$fechaHasta, region=$regionBusqueda, provincia=$provinciaBusqueda, comuna=$comunaBusqueda');
  }

  Future _seleccionarFecha(BuildContext context, bool esDesde) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: esDesde ? (fechaDesde ?? DateTime.now()) : (fechaHasta ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (esDesde) {
          fechaDesde = picked;
        } else {
          fechaHasta = picked;
        }
      });
    }
  }

  void _filtrar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UsuariosFiltrados(
          region: regionBusqueda,
          provincia: provinciaBusqueda,
          comuna: comunaBusqueda,
          sexo: sexoSeleccionado,
          aptoParaDonar: aptoParaDonar,
          tipoSangre: tipoSangreSeleccionado,
          fechaDesde: fechaDesde,
          fechaHasta: fechaHasta,
        ),
      ),
    );
  }

  void _borrarFiltros() {
    setState(() {
      sexoSeleccionado = null;
      aptoParaDonar = null;
      tipoSangreSeleccionado = null;
      fechaDesde = null;
      fechaHasta = null;
      comunaBusqueda = null;
      regionBusqueda = null;
      provinciaBusqueda = null;
      _aplicadoInicial = false; // permite re-aplicar si vuelves con otros args
    });
  }

  InputDecoration _inputDecoration(String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  bool get _hayFiltrosAplicados {
    return sexoSeleccionado != null ||
        aptoParaDonar != null ||
        tipoSangreSeleccionado != null ||
        fechaDesde != null ||
        fechaHasta != null ||
        comunaBusqueda != null ||
        regionBusqueda != null ||
        provinciaBusqueda != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final regiones = todasUbicaciones.map((e) => e.region).toSet().toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Filtrar Usuarios'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Sexo
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(isDarkMode ? 0.1 : 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                decoration: _inputDecoration('Sexo'),
                value: sexoSeleccionado,
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Femenino')),
                  DropdownMenuItem(value: 'O', child: Text('Otro')),
                ],
                onChanged: (value) => setState(() => sexoSeleccionado = value),
              ),
            ),

            // Apto para donar
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(isDarkMode ? 0.1 : 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<bool>(
                decoration: _inputDecoration('Apto para donar'),
                value: aptoParaDonar,
                items: const [
                  DropdownMenuItem(value: true, child: Text('Sí')),
                  DropdownMenuItem(value: false, child: Text('No')),
                ],
                onChanged: (value) => setState(() => aptoParaDonar = value),
              ),
            ),

            // Tipo sangre
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(isDarkMode ? 0.1 : 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                decoration: _inputDecoration('Tipo de sangre'),
                value: tipoSangreSeleccionado,
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) => setState(() => tipoSangreSeleccionado = value),
              ),
            ),

            // Región
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(isDarkMode ? 0.1 : 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                decoration: _inputDecoration('Región'),
                value: regionBusqueda,
                items: regiones
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    regionBusqueda = value;
                    provinciaBusqueda = null;
                    comunaBusqueda = null;
                  });
                },
              ),
            ),

            // Provincia
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(isDarkMode ? 0.1 : 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                decoration: _inputDecoration('Provincia'),
                value: provinciaBusqueda,
                items: (regionBusqueda == null
                        ? todasUbicaciones
                        : todasUbicaciones.where((u) => u.region == regionBusqueda))
                    .map((u) => u.provincia)
                    .toSet()
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    provinciaBusqueda = value;
                    comunaBusqueda = null;
                  });
                },
              ),
            ),

            // Comuna
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(isDarkMode ? 0.1 : 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                decoration: _inputDecoration('Comuna'),
                value: comunaBusqueda,
                items: (provinciaBusqueda == null
                        ? (regionBusqueda == null
                            ? todasUbicaciones
                            : todasUbicaciones.where((u) => u.region == regionBusqueda))
                        : todasUbicaciones.where((u) => u.provincia == provinciaBusqueda))
                    .map((u) => u.comuna)
                    .toSet()
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => comunaBusqueda = value),
              ),
            ),

            // Fechas
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, bottom: 24),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(isDarkMode ? 0.1 : 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _seleccionarFecha(context, true),
                      child: Text(
                        fechaDesde == null
                            ? 'Fecha desde'
                            : 'Desde: ${fechaDesde!.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8, bottom: 24),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(isDarkMode ? 0.1 : 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _seleccionarFecha(context, false),
                      child: Text(
                        fechaHasta == null
                            ? 'Fecha hasta'
                            : 'Hasta: ${fechaHasta!.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_hayFiltrosAplicados)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton(
                  onPressed: _borrarFiltros,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: theme.colorScheme.error,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Borrar filtros'),
                ),
              ),

            ElevatedButton.icon(
              onPressed: _filtrar,
              icon: const Icon(Icons.send),
              label: const Text('Filtrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UsuariosFiltrados extends StatelessWidget {
  final String? region;
  final String? provincia;
  final String? comuna;
  final String? sexo;
  final bool? aptoParaDonar;
  final String? tipoSangre;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  const UsuariosFiltrados({
    super.key,
    this.region,
    this.provincia,
    this.comuna,
    this.sexo,
    this.aptoParaDonar,
    this.tipoSangre,
    this.fechaDesde,
    this.fechaHasta,
  });

  Future<String?> seleccionarDirectorioGuardado() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    return selectedDirectory;
  }

  void exportToExcel(List<UserProfile> usuarios, context) async {
    // ... (tu lógica de exportación existente)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios Filtrados')),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<List<UserProfile>>(
        future: fetchUsers(
          region: region,
          provincia: provincia,
          comuna: comuna,
          sexo: sexo,
          aptoParaDonar: aptoParaDonar,
          tipoSangre: tipoSangre,
          fechaDesde: fechaDesde,
          fechaHasta: fechaHasta,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No se encontraron donantes para los filtros seleccionados.'));
          } else if (snapshot.hasData) {
            final usuarios = snapshot.data!;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Total de usuarios encontrados: ${usuarios.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      final user = usuarios[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(isDarkMode ? 0.1 : 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.nombre ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Sexo: ${user.sexo ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16)),
                              Text('Apto para donar: ${user.aptoParaDonar == true ? 'Sí' : 'No'}',
                                  style: const TextStyle(fontSize: 16)),
                              Text('Tipo de sangre: ${user.tipoSangre ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16)),
                              Text('Región: ${user.region ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16)),
                              Text('Provincia: ${user.provincia ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16)),
                              Text('Comuna: ${user.comuna ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 16)),
                              Text('Fecha última donación: ${formatFecha(user.fechaUltimaDonacion)}',
                                  style: const TextStyle(fontSize: 16)),
                              Text('Próxima donación posible: ${formatFecha(user.proximaDonacion)}',
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: ElevatedButton.icon(
                    onPressed: () => exportToExcel(usuarios, context),
                    icon: const Icon(Icons.file_download),
                    label: const Text('Exportar a Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('Error desconocido.'));
        },
      ),
    );
  }
}
