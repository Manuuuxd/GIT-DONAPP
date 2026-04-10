import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:donapp_android/CONFIG/api_config.dart';

const MAPBOX_ACCESS_TOKEN =
    'TOKEN GENERICO';

class MapScreen extends StatefulWidget {
  final LatLng? focusOn;
  final dynamic focusCampania;

  const MapScreen({super.key, this.focusOn, this.focusCampania});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  List<dynamic> _campanias = [];
  List<Map<String, dynamic>> _campaniasProcesadas = [];
  String _selectedFecha = "Todas";
  bool _movedToFocus = false;
  bool _showFilter = false;
  List<Marker> _markersCache = [];

  @override
  void initState() {
    super.initState();
    _listenToLocation();
    fetchCampanias();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusCampania != null &&
        widget.focusCampania != oldWidget.focusCampania) {
        debugPrint("Mostrando popup para campaña enfocada desde didUpdateWidget");
        _showCampaniaPopupFromFocus(widget.focusCampania);
    }
  }

  


  Future<void> _listenToLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      _showPermissionDialog();
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (!mounted) return;

      LatLng newPosition = LatLng(position.latitude, position.longitude);

      if (_currentPosition == null ||
          _distanceBetween(_currentPosition!, newPosition) > 5) {
        setState(() {
          _currentPosition = newPosition;

          if (widget.focusOn != null && !_movedToFocus) {
            _mapController.move(widget.focusOn!, 16);
            _movedToFocus = true;
          }
          _updateMarkers();
        });
      }
    });
  }


  double _distanceBetween(LatLng a, LatLng b) {
    final Distance distance = Distance();
    return distance(a, b);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _showPermissionDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Permiso de ubicación requerido"),
      content: const Text(
          "Necesitamos tu ubicación para mostrar campañas cercanas. Concede permisos para continuar."),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            LocationPermission permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always) {
              // Reiniciar la escucha para obtener ubicación
              _listenToLocation();
              setState(() {}); // Forzar redibujado por si acaso
            }
          },
          child: const Text("Conceder permiso"),
        ),
      ],
    ),
  );
}


  void openMapNavigation(LatLng coords) async {
    if (await MapLauncher.isMapAvailable(MapType.google)) {
      await MapLauncher.showDirections(
        destination: Coords(coords.latitude, coords.longitude),
        mapType: MapType.google,
        directionsMode: DirectionsMode.driving,
      );
    } else {
      final availableMaps = await MapLauncher.installedMaps;
      if (availableMaps.isNotEmpty) {
        await availableMaps.first.showDirections(
          destination: Coords(coords.latitude, coords.longitude),
          directionsMode: DirectionsMode.driving,
        );
      } else {
        debugPrint("No hay aplicaciones de mapas disponibles.");
      }
    }
  }

  String formatFecha(String? fecha) {
    if (fecha == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(fecha);
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  Future<void> fetchCampanias() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('authToken');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
    };
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint("api/campanias/campanias/")),
        headers: headers,
      );
      if (response.statusCode == 200) {
        List<dynamic> rawCampanias = jsonDecode(response.body);

        _campaniasProcesadas = rawCampanias.map((c) {
          DateTime? fechaParsed;
          try {
            fechaParsed = DateTime.parse(c["fecha"] ?? "");
          } catch (_) {
            fechaParsed = null;
          }
          return {
            'data': c,
            'fechaParsed': fechaParsed,
          };
        }).toList();

        setState(() {
          _campanias = rawCampanias;
          _updateMarkers();
        });
      } else {
        debugPrint("Error al cargar campañas: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error de conexión: $e");
    }
  }

  void _updateMarkers() {
    if (_currentPosition == null) return;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    bool esFuturaOCorriente(Map<String, dynamic> campania) {
      final fecha = campania['fechaParsed'] as DateTime?;
      if (fecha == null) return false;
      final campaniaDate = DateTime(fecha.year, fecha.month, fecha.day);
      return !campaniaDate.isBefore(todayDate);
    }

    List<Map<String, dynamic>> filtered = [];

    if (_selectedFecha == "Todas") {
      filtered = _campaniasProcesadas.where(esFuturaOCorriente).toList();
    } else {
      filtered =
          _campaniasProcesadas.where((c) {
            return esFuturaOCorriente(c) &&
                formatFecha(c['data']["fecha"]) == _selectedFecha;
          }).toList();
    }

    List<Marker> nuevosMarkers = [
      Marker(
        point: _currentPosition!,
        width: 50,
        height: 50,
        child: const Icon(Icons.person_pin, color: Colors.blueAccent, size: 30),
      )
    ];

    for (var c in filtered) {
      final campania = c['data'];
      final lat = (campania['latitud'] as num?)?.toDouble();
      final lng = (campania['longitud'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      nuevosMarkers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              _mapController.move(LatLng(lat, lng), 18);
              _showCampaniaPopup(campania, LatLng(lat, lng));
            },
            child: const Icon(Icons.location_on, color: Colors.red, size: 35),
          ),
        ),
      );
    }

    _markersCache = nuevosMarkers;
  }

  bool _mapReady = false;

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final today = DateTime.now();
    final fechasSet = <String>{};
    for (var c in _campaniasProcesadas) {
      final d = c['fechaParsed'] as DateTime?;
      if (d != null && !d.isBefore(DateTime(today.year, today.month, today.day))) {
        fechasSet.add(formatFecha(d.toIso8601String()));
      }
    }
    List<String> fechas = fechasSet.toList();
    fechas.sort();
    fechas.insert(0, "Todas");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de campañas"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchCampanias,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              onMapReady: (){
                setState(() {
                  _mapReady = true;
                });

                if (widget.focusCampania !=null){
                  debugPrint("Mostrando popup para campaña enfocada desde onMapReady");
                  _showCampaniaPopupFromFocus(widget.focusCampania);
                }
              },
              initialCenter: widget.focusOn ?? _currentPosition!,
              initialZoom: 18,
              minZoom: 4,
              maxZoom: 25,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                additionalOptions: {
                  'accessToken': MAPBOX_ACCESS_TOKEN,
                  'id': 'mapbox/streets-v12',
                },
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(40, 40),
                  markers: _markersCache,
                  builder: (context, markers) => Container(
                    decoration:
                        const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: Center(
                      child: Text("${markers.length}",
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showFilter)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedFecha,
                    decoration: const InputDecoration(
                      labelText: "Filtrar por fecha",
                      border: OutlineInputBorder(),
                    ),
                    items: fechas.map((fecha) {
                      return DropdownMenuItem(value: fecha, child: Text(fecha));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFecha = value!;
                        _updateMarkers();
                      });
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn_location",
            backgroundColor: Colors.blueAccent,
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(_currentPosition!, 18);
              }
              _mapController.rotate(0);
            },
            mini: true,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
          FloatingActionButton(
            heroTag: "btn_filter",
            backgroundColor: Colors.blueAccent,
            onPressed: () {
              setState(() {
                _showFilter = !_showFilter;
              });
            },
            mini: true,
            child: const Icon(Icons.filter_alt, color: Colors.white),
          ),
          FloatingActionButton(
            heroTag: "btn_reset_rotation",
            backgroundColor: Colors.blueAccent,
            onPressed: () {
              _mapController.rotate(0);
            },
            mini: true,
            child: const Icon(Icons.explore, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showCampaniaPopup(dynamic campania, LatLng coords) {
    showDialog(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text("Detalle de campaña",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 40),
                ],
              ),
              Text(campania['nombre'] ?? "Campaña",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("Fecha: ${formatFecha(campania["fecha"])}"),
              Text("Dirección: ${(campania["direccion"] ?? "").toString().split(',').first}"),
              Text("Comuna: ${campania["comuna"] ?? ""}"),
              Text("Horario: ${campania["horario"] ?? ""}"),
              Text("Grupo sanguíneo: ${campania["grupo_sanguineo"] ?? ""}"),
              Text("Rh: ${campania["rh"] ?? ""}"),
              Text("Estado: ${campania["estado"] ?? ""}"),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => openMapNavigation(coords),
                icon: const Icon(Icons.directions),
                label: const Text("Cómo llegar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCampaniaPopupFromFocus(dynamic campania) async {
    final lat = (campania['latitud'] as num?)?.toDouble();
    final lng = (campania['longitud'] as num?)?.toDouble();
    debugPrint("Coordenadas de la campaña enfocada: lat=$lat, lng=$lng");
    if (lat == null || lng == null) return;

    final coords = LatLng(lat, lng);

    // Esperar hasta que el mapa esté listo (máximo 2 segundos aprox.)
    int waited = 0;
    while (!_mapReady && waited < 40) {
      await Future.delayed(const Duration(milliseconds: 50));
      waited++;
    }

    if (!_mapReady) {
      debugPrint("Mapa no está listo después de 2 segundos, no se mueve");
      return;
    }

    _mapController.move(coords, 18);
    _showCampaniaPopup(campania, coords);
}

}