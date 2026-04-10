import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:fl_chart/fl_chart.dart';
// Importamos AppColors por si queremos usar colores semánticos (ej. 'success')
// (Aunque en esta versión los reemplazaremos por colores del tema)
// import 'package:donapp_android/colours/app_colors.dart'; 

class MetricasScreen extends StatefulWidget {
  const MetricasScreen({super.key});

  @override
  State<MetricasScreen> createState() => _MetricasScreenState();
}

class _MetricasScreenState extends State<MetricasScreen> {
  bool _isLoading = true;
  String _selectedMetric = "xp"; // xp, donaciones, compartidos
  List<dynamic> _metricData = [];
  DateTimeRange? _dateRange;

  String? sexo; // M o F
  DateTime? ultimaDonacion;

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndMetrics();
  }

  Future<void> _fetchUserDataAndMetrics() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      await _fetchMetrics(); // fallback solo mock
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(ApiConfig.endpoint("api/users/me/")),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        sexo = data['profile']?['sexo'];
        final fechaUlt = data['profile']?['fecha_ultima_donacion'];
        if (fechaUlt != null) ultimaDonacion = DateTime.parse(fechaUlt);
      }
    } catch (e) {
      debugPrint("Error obteniendo usuario: $e");
    }

    await _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600)); // Simula carga

    final now = DateTime.now();
    List<Map<String, dynamic>> mockData = [];

    if (_selectedMetric == "xp") {
      // XP sube cada mes con progresión leve
      mockData = List.generate(6, (i) {
        final month = DateTime(now.year, now.month - (5 - i));
        return {
          "date": "${month.year}-${month.month.toString().padLeft(2, '0')}-01",
          "value": 100 + i * 80 + Random().nextInt(50)
        };
      });
    }

    else if (_selectedMetric == "donaciones") {
      if (ultimaDonacion == null) {
        setState(() {
          _metricData = [];
          _isLoading = false;
        });
        return;
      }

      final intervaloMeses = (sexo == "F") ? 4 : 3;
      final donaciones = <DateTime>[];
      DateTime fecha = ultimaDonacion!;

      while (fecha.isBefore(now)) {
        donaciones.add(fecha);
        fecha = DateTime(fecha.year, fecha.month + intervaloMeses, fecha.day);
      }

      mockData = donaciones.map((d) {
        return {
          "date": "${d.year}-${d.month.toString().padLeft(2, '0')}-01",
          "value": 1,
        };
      }).toList();
    }

    else if (_selectedMetric == "compartidos") {
      // Compartidos aleatorios
      mockData = List.generate(6, (i) {
        final month = DateTime(now.year, now.month - (5 - i));
        return {
          "date": "${month.year}-${month.month.toString().padLeft(2, '0')}-01",
          "value": 3 + Random().nextInt(10)
        };
      });
    }

    setState(() {
      _metricData = mockData;
      _isLoading = false;
    });
  }

  // --- 1. Adaptamos los colores ---
  Color _metricColor(ColorScheme colorScheme) {
    switch (_selectedMetric) {
      case "xp":
        return colorScheme.primary; // <-- Cambio
      case "donaciones":
        return colorScheme.secondary; // <-- Cambio
      case "compartidos":
        return colorScheme.tertiary; // <-- Cambio
      default:
        return colorScheme.onSurfaceVariant; // <-- Cambio
    }
  }

  String _metricLabel() {
    switch (_selectedMetric) {
      case "xp":
        return "Experiencia acumulada";
      case "donaciones":
        return "Donaciones realizadas";
      case "compartidos":
        return "Veces compartido";
      default:
        return "";
    }
  }

  // --- 2. Pasamos el tema y el colorScheme ---
  Widget _buildChart(ThemeData theme, ColorScheme colorScheme) {
    if (_selectedMetric == "donaciones" && ultimaDonacion == null) {
      return Center(
        child: Text(
          "No has registrado tus donaciones",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant), // <-- Cambio
        ),
      );
    }

    if (_metricData.isEmpty) {
      return const Center(child: Text("No hay datos disponibles."));
    }

    final spots = _metricData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble());
    }).toList();

    final color = _metricColor(colorScheme); // <-- Cambio
    
    // --- 3. Corrección de error (Clamp) ---
    // Nos aseguramos que maxY sea al menos 1.0 para evitar errores de división por cero
    final maxYValue = _metricData.map((e) => (e['value'] as num).toDouble()).reduce(max);
    final maxY = (maxYValue * 1.2).clamp(1.0, double.maxFinite);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            _metricLabel(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // El color (onSurface) se hereda del tema
          ),
        ),
        Expanded(
          child: LineChart(
            LineChartData(
              // --- 4. Corrección de error (double) ---
              minY: 0.0, // <-- Cambio (era 0)
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outline.withOpacity(0.2), // <-- Cambio
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _metricData.length) return const SizedBox();
                      final dateStr = _metricData[index]['date'];
                      final month = DateTime.parse(dateStr).month;
                      const months = [
                        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
                      ];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          months[month - 1],
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant), // <-- Cambio
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    // --- 5. Corrección de error (Intervalo) ---
                    interval: (maxY / 5).clamp(1.0, double.maxFinite), // <-- Cambio
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant), // <-- Cambio
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.3), colorScheme.surface.withOpacity(0.0)], // <-- Cambio
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  dotData: FlDotData(show: true),
                  spots: spots,
                  barWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _fetchMetrics();
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 6. Obtenemos el tema ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
      appBar: AppBar(
        title: const Text("Mis métricas"),
        backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
        elevation: 1, // <-- (Opcional)
        foregroundColor: colorScheme.onBackground, // <-- Cambio
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // FILTROS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedMetric,
                  // El dropdown usará los colores del tema automáticamente
                  items: const [
                    DropdownMenuItem(value: "xp", child: Text("Experiencia")),
                    DropdownMenuItem(value: "donaciones", child: Text("Donaciones")),
                    DropdownMenuItem(value: "compartidos", child: Text("Compartidos")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMetric = value!;
                      _fetchMetrics();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: _selectDateRange,
                  // El icono usará los colores del tema automáticamente
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildChart(theme, colorScheme), // <-- 7. Pasamos el tema
            ),
          ],
        ),
      ),
    );
  }
}
