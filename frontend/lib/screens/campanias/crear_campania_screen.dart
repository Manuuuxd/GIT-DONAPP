import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'enviar_notificacion_screen.dart'; // pantalla de enviar notificaciones
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:donapp_android/main.dart';
import 'package:donapp_android/screens/map/campaign_notifier.dart';

const kGoogleApiKey = "AIzaSyBEPm5qLP76qzqphHV0DHpjkuaqYyNk8z4";

class CrearCampaniaScreen extends StatefulWidget {
  final String jwtToken;
  final Map<String, dynamic>? campania;     // edición existente
  final Map<String, dynamic>? initialForm;  // ← payload del asistente

  const CrearCampaniaScreen({
    super.key,
    required this.jwtToken,
    this.campania,
    this.initialForm,
  });

  @override
  State<CrearCampaniaScreen> createState() => _CrearCampaniaScreenState();
}

class _CrearCampaniaScreenState extends State<CrearCampaniaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _comunaROController = TextEditingController();
  final TextEditingController _fechaROController = TextEditingController();

  List<dynamic> _predictions = [];

  String nombre = "";
  String direccion = "";
  String comuna = "";
  DateTime? fecha;
  String horario = "";
  String grupoSanguineo = "A"; // A | B | AB | O
  String? rh;                  // + | -
  double? lat;
  double? lng;

  @override
  void initState() {
    super.initState();

    // 1) Si viene una campaña para edición, hidrata primero
    if (widget.campania != null) {
      final c = widget.campania!;
      nombre = (c["nombre"] ?? "").toString();
      direccion = (c["direccion"] ?? "").toString();
      comuna = (c["comuna"] ?? "").toString();
      horario = (c["horario"] ?? "").toString();
      grupoSanguineo = (c["grupo_sanguineo"] ?? "A").toString();
      rh = (c["rh"]?.toString().isNotEmpty ?? false) ? c["rh"].toString() : null;
      lat = (c["latitud"] as num?)?.toDouble();
      lng = (c["longitud"] as num?)?.toDouble();

      final f = (c["fecha"] ?? "").toString();
      if (f.isNotEmpty) fecha = DateTime.tryParse(f);
    }

    // 2) Overlay desde el asistente (solo completa lo faltante)
    _hydrateFromAssistant(widget.initialForm);

    // 3) sincroniza controladores de solo lectura
    _direccionController.text = direccion;
    _comunaROController.text = comuna;
    _fechaROController.text = _fmtFechaVisual(fecha);
  }

  // ===================== Helpers de parseo =====================
  void _applyGrupo(String? g) {
    if (g == null) return;
    final t = g.trim().toUpperCase(); // ejemplos: O+, O -, O POSITIVO, AB-, A NEG
    final re = RegExp(r'^(AB|A|B|O)\s*(\+|-|POS(?:ITIVO)?|NEG(?:ATIVO)?)?$');
    final m = re.firstMatch(t);
    if (m == null) return;

    final letra = m.group(1)!;
    final signoRaw = (m.group(2) ?? "").toUpperCase().replaceAll(' ', '');
    String? signo;
    if (signoRaw == '+' || signoRaw == 'POS' || signoRaw == 'POSITIVO') signo = '+';
    if (signoRaw == '-' || signoRaw == 'NEG' || signoRaw == 'NEGATIVO') signo = '-';

    grupoSanguineo = letra;
    rh = signo ?? rh; // si no vino signo, no pisa el existente
  }

  void _hydrateFromAssistant(Map<String, dynamic>? form) {
    if (form == null) return;

    // titulo -> nombre
    final titulo = (form['titulo'] ?? '').toString();
    if (titulo.isNotEmpty && nombre.isEmpty) nombre = titulo;

    // fecha_iso -> fecha
    final fechaIso = (form['fecha_iso'] ?? '').toString();
    if (fechaIso.isNotEmpty && fecha == null) {
      fecha = DateTime.tryParse(fechaIso);
    }

    // hora/hora_fin -> horario "HH:mm - HH:mm" (si ambas existen)
    final h1 = (form['hora'] ?? '').toString();
    final h2 = (form['hora_fin'] ?? '').toString();
    if (horario.isEmpty) {
      if (h1.isNotEmpty && h2.isNotEmpty) {
        horario = "$h1 - $h2";
      } else if (h1.isNotEmpty) {
        horario = h1;
      }
    }

    // grupo_sanguineo -> split en grupoSanguineo y rh
    final g = (form['grupo_sanguineo'] ?? '').toString();
    if (g.isNotEmpty) _applyGrupo(g);

    // comuna (solo si no viene desde edición)
    final c = (form['comuna'] ?? '').toString();
    if (comuna.isEmpty && c.isNotEmpty) comuna = c;

    // centro -> como dirección si está vacía
    final centro = (form['centro'] ?? '').toString();
    if (direccion.isEmpty && centro.isNotEmpty) direccion = centro;

    // refresca los RO controllers
    _direccionController.text = direccion;
    _comunaROController.text = comuna;
    _fechaROController.text = _fmtFechaVisual(fecha);
  }

  String _fmtFechaIso(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _fmtFechaVisual(DateTime? d) =>
      d == null ? "" : "${d.day}/${d.month}/${d.year}";

  // ===================== Autocomplete (Google Places) =====================
  Future<void> _buscarPredicciones(String input) async {
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$kGoogleApiKey&components=country:cl';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _predictions = data['predictions'];
      });
    } else {
      // ignore: avoid_print
      print("Error Places API: ${response.body}");
    }
  }

  Future<void> _seleccionarPrediccion(String placeId, String descripcion) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$kGoogleApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['result'];
      final location = data['geometry']['location'];

      final comps = data['address_components'] as List<dynamic>;
      final compComuna = comps.firstWhere(
        (c) => (c['types'] as List).contains('locality'),
        orElse: () => comps.first,
      );

      setState(() {
        direccion = (data['formatted_address'] ?? descripcion).toString();
        lat = (location['lat'] as num?)?.toDouble();
        lng = (location['lng'] as num?)?.toDouble();
        comuna = (compComuna['long_name'] ?? '').toString();

        _direccionController.text = direccion;
        _comunaROController.text = comuna;
        _predictions = [];
      });
    } else {
      // ignore: avoid_print
      print("Error Place Details: ${response.body}");
    }
  }

  // ===================== DatePicker =====================
  Future<void> _seleccionarFecha(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fecha ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        fecha = picked;
        _fechaROController.text = _fmtFechaVisual(fecha);
      });
    }
  }

  // ===================== Crear o Editar campaña =====================
  Future<void> _guardarCampania() async {
    if (_formKey.currentState!.validate() && fecha != null) {
      final body = jsonEncode({
        "nombre": nombre,
        "direccion": direccion,
        "comuna": comuna,
        "latitud": lat,
        "longitud": lng,
        "fecha": _fmtFechaIso(fecha!),
        "horario": horario,
        "grupo_sanguineo": grupoSanguineo,
        "rh": rh,
      });

      final bool esEdicion = widget.campania != null;
      final url = esEdicion
          ? "http://10.0.2.2:8000/api/campanias/campanias/${widget.campania!['id']}/"
          : ApiConfig.endpoint("api/campanias/campanias/");

      final response = esEdicion
          ? await http.put(Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer ${widget.jwtToken}",
              },
              body: body)
          : await http.post(Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer ${widget.jwtToken}",
              },
              body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final campaniaCreada = jsonDecode(response.body);

        // Notificar creación/edición de campaña
        debugPrint("Notificando creación/edición de campaña...");
        final notifier = CampaignNotifier(
          apiBaseUrl: ApiConfig.baseUrl,
          authToken: widget.jwtToken,
          navigatorKey: navigatorKey,
        );
        await notifier.init();
        await notifier.notifyCreatedCampaign(campaniaCreada);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esEdicion
                ? "Campaña editada exitosamente"
                : "Campaña creada exitosamente"),
          ),
        );

        // Preguntar si quiere ir a notificaciones
        final irANotificaciones = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("¿Enviar notificaciones?"),
            content: const Text(
                "¿Deseas ir a la pantalla de envío de notificaciones para esta campaña?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("No")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Sí")),
            ],
          ),
        );

        if (irANotificaciones == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EnviarNotificacionScreen(
                jwtToken: widget.jwtToken,
                campania: campaniaCreada,
              ),
            ),
          );
        } else {
          Navigator.pop(context, true); // vuelve a la pantalla anterior
        }
      } else {
        // ignore: avoid_print
        print("Error ${response.statusCode}: ${response.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esEdicion
                ? "Error al editar campaña"
                : "Error al crear campaña"),
          ),
        );
      }
    } else if (fecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona una fecha")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.campania != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? "Editar Campaña" : "Crear Campaña"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Nombre
                TextFormField(
                  initialValue: nombre,
                  decoration: const InputDecoration(labelText: "Nombre"),
                  onChanged: (val) => nombre = val,
                  validator: (val) => val!.isEmpty ? "Ingrese un nombre" : null,
                ),
                const SizedBox(height: 10),

                // Dirección con Autocomplete
                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(labelText: "Dirección"),
                  onChanged: _buscarPredicciones,
                  validator: (val) =>
                      val!.isEmpty ? "Seleccione una dirección" : null,
                ),
                if (_predictions.isNotEmpty)
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final pred = _predictions[index];
                        return ListTile(
                          title: Text(pred['description']),
                          onTap: () => _seleccionarPrediccion(
                              pred['place_id'], pred['description']),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),

                // Comuna (solo lectura, la rellena el autocomplete o el asistente)
                TextFormField(
                  decoration: const InputDecoration(labelText: "Comuna"),
                  readOnly: true,
                  controller: _comunaROController,
                ),
                const SizedBox(height: 10),

                // Fecha (solo lectura con picker)
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Fecha",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _seleccionarFecha(context),
                    ),
                  ),
                  controller: _fechaROController,
                ),
                const SizedBox(height: 10),

                // Horario
                TextFormField(
                  initialValue: horario,
                  decoration: const InputDecoration(labelText: "Horario"),
                  onChanged: (val) => horario = val,
                ),
                const SizedBox(height: 10),

                // Grupo sanguíneo (letra) y Rh
                DropdownButtonFormField(
                  value: grupoSanguineo,
                  items: const [
                    DropdownMenuItem(value: "A", child: Text("A")),
                    DropdownMenuItem(value: "B", child: Text("B")),
                    DropdownMenuItem(value: "AB", child: Text("AB")),
                    DropdownMenuItem(value: "O", child: Text("O")),
                  ],
                  onChanged: (val) => grupoSanguineo = val!,
                  decoration:
                      const InputDecoration(labelText: "Grupo sanguíneo"),
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField(
                  value: rh,
                  items: const [
                    DropdownMenuItem(value: "+", child: Text("Rh +")),
                    DropdownMenuItem(value: "-", child: Text("Rh -")),
                  ],
                  onChanged: (val) => rh = val,
                  decoration: const InputDecoration(labelText: "Rh (opcional)"),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _guardarCampania,
                  child: Text(esEdicion ? "Guardar cambios" : "Crear campaña"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
