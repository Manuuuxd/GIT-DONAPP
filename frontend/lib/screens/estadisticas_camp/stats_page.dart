import 'dart:convert' show utf8;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

/// ======================
/// 1) MODELOS
/// ======================

enum EventType { invited, confirmed, attended, reaction, scheduled }

class Campaign {
  final String id;
  final String name;
  final String type;
  final String location;
  final String status;
  final DateTime startDate;
  final DateTime endDate;

  Campaign({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.status,
    required this.startDate,
    required this.endDate,
  });
}

class Event {
  final String id;
  final String campaignId;
  final EventType type;
  final DateTime timestamp;
  final Map<String, dynamic>? meta;

  Event({
    required this.id,
    required this.campaignId,
    required this.type,
    required this.timestamp,
    this.meta,
  });
}

class Kpis {
  final int convocados;
  final int confirmados;
  final int asistencia;
  final double tasaNoShow; // 0..1
  final int reacciones;
  final int agendamientos;

  Kpis({
    required this.convocados,
    required this.confirmados,
    required this.asistencia,
    required this.tasaNoShow,
    required this.reacciones,
    required this.agendamientos,
  });
}

/// ======================
/// 2) DATA MOCK (para validar)
/// ======================

class MockData {
  static final List<Campaign> campaigns = [
    Campaign(
      id: 'c1',
      name: 'Campaña Septiembre RRSS',
      type: 'RRSS',
      location: 'Providencia',
      status: 'cerrada',
      startDate: DateTime(2025, 9, 1),
      endDate: DateTime(2025, 9, 7),
    ),
    Campaign(
      id: 'c2',
      name: 'Puntos Fijos Mall',
      type: 'Terreno',
      location: 'Maipú',
      status: 'activa',
      startDate: DateTime(2025, 9, 3),
      endDate: DateTime(2025, 9, 15),
    ),
    Campaign(
      id: 'c3',
      name: 'Emailing Primavera',
      type: 'Email',
      location: 'Ñuñoa',
      status: 'cerrada',
      startDate: DateTime(2025, 8, 20),
      endDate: DateTime(2025, 9, 5),
    ),
  ];

  static final List<Event> events = [
    // c1
    ...List.generate(
        40,
        (i) => Event(
              id: 'e1_$i',
              campaignId: 'c1',
              type: EventType.invited,
              timestamp: DateTime(2025, 9, 1).add(Duration(hours: i)),
            )),
    ...List.generate(
        25,
        (i) => Event(
              id: 'e1c_$i',
              campaignId: 'c1',
              type: EventType.confirmed,
              timestamp: DateTime(2025, 9, 2).add(Duration(hours: i)),
            )),
    ...List.generate(
        20,
        (i) => Event(
              id: 'e1a_$i',
              campaignId: 'c1',
              type: EventType.attended,
              timestamp: DateTime(2025, 9, 3).add(Duration(hours: i)),
            )),
    ...List.generate(
        10,
        (i) => Event(
              id: 'e1r_$i',
              campaignId: 'c1',
              type: EventType.reaction,
              timestamp: DateTime(2025, 9, 2, 12).add(Duration(hours: i)),
            )),
    ...List.generate(
        12,
        (i) => Event(
              id: 'e1s_$i',
              campaignId: 'c1',
              type: EventType.scheduled,
              timestamp: DateTime(2025, 9, 4).add(Duration(hours: i)),
            )),

    // c2
    ...List.generate(
        90,
        (i) => Event(
              id: 'e2_$i',
              campaignId: 'c2',
              type: EventType.invited,
              timestamp: DateTime(2025, 9, 3).add(Duration(hours: i)),
            )),
    ...List.generate(
        50,
        (i) => Event(
              id: 'e2c_$i',
              campaignId: 'c2',
              type: EventType.confirmed,
              timestamp: DateTime(2025, 9, 5).add(Duration(hours: i)),
            )),
    ...List.generate(
        35,
        (i) => Event(
              id: 'e2a_$i',
              campaignId: 'c2',
              type: EventType.attended,
              timestamp: DateTime(2025, 9, 6).add(Duration(hours: i)),
            )),
    ...List.generate(
        15,
        (i) => Event(
              id: 'e2r_$i',
              campaignId: 'c2',
              type: EventType.reaction,
              timestamp: DateTime(2025, 9, 7).add(Duration(hours: i)),
            )),
    ...List.generate(
        18,
        (i) => Event(
              id: 'e2s_$i',
              campaignId: 'c2',
              type: EventType.scheduled,
              timestamp: DateTime(2025, 9, 8).add(Duration(hours: i)),
            )),

    // c3
    ...List.generate(
        60,
        (i) => Event(
              id: 'e3_$i',
              campaignId: 'c3',
              type: EventType.invited,
              timestamp: DateTime(2025, 8, 22).add(Duration(hours: i)),
            )),
    ...List.generate(
        30,
        (i) => Event(
              id: 'e3c_$i',
              campaignId: 'c3',
              type: EventType.confirmed,
              timestamp: DateTime(2025, 8, 25).add(Duration(hours: i)),
            )),
    ...List.generate(
        28,
        (i) => Event(
              id: 'e3a_$i',
              campaignId: 'c3',
              type: EventType.attended,
              timestamp: DateTime(2025, 8, 28).add(Duration(hours: i)),
            )),
    ...List.generate(
        9,
        (i) => Event(
              id: 'e3r_$i',
              campaignId: 'c3',
              type: EventType.reaction,
              timestamp: DateTime(2025, 8, 26).add(Duration(hours: i)),
            )),
    ...List.generate(
        14,
        (i) => Event(
              id: 'e3s_$i',
              campaignId: 'c3',
              type: EventType.scheduled,
              timestamp: DateTime(2025, 8, 30).add(Duration(hours: i)),
            )),
  ];
}

/// ======================
/// 3) ESTADO, FILTROS, KPIs
/// ======================

enum ChartType { bar, line, scatter }

class StatsFilter {
  String? type;
  String? location;
  String? status;
  DateTimeRange? dateRange;
  List<String> selectedCampaignIds;
  bool compareMode;

  StatsFilter({
    this.type,
    this.location,
    this.status,
    this.dateRange,
    List<String>? selectedCampaignIds,
    this.compareMode = false,
  }) : selectedCampaignIds = selectedCampaignIds ?? [];
}

class StatsState extends ChangeNotifier {
  final List<Campaign> allCampaigns;
  final List<Event> allEvents;

  StatsFilter filter = StatsFilter();
  ChartType chartType = ChartType.bar;

  StatsState(this.allCampaigns, this.allEvents);

  void setChartType(ChartType t) {
    chartType = t;
    notifyListeners();
  }

  void setFilter(StatsFilter f) {
    filter = f;
    notifyListeners();
  }

  List<Campaign> get filteredCampaigns {
    return allCampaigns.where((c) {
      final byType = filter.type == null || c.type == filter.type;
      final byLoc = filter.location == null || c.location == filter.location;
      final bySt = filter.status == null || c.status == filter.status;
      final byDate = filter.dateRange == null ||
          _overlaps(c.startDate, c.endDate, filter.dateRange!);
      final bySel = filter.selectedCampaignIds.isEmpty ||
          filter.selectedCampaignIds.contains(c.id);
      return byType && byLoc && bySt && byDate && bySel;
    }).toList();
  }

  static bool _overlaps(DateTime aStart, DateTime aEnd, DateTimeRange r) {
    final bStart = r.start;
    final bEnd = r.end;
    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  List<Event> get filteredEvents {
    final ids = filteredCampaigns.map((c) => c.id).toSet();
    return allEvents.where((e) {
      final inCampaign = ids.contains(e.campaignId);
      final inRange = filter.dateRange == null
          ? true
          : (e.timestamp.isAfter(filter.dateRange!.start
                  .subtract(const Duration(milliseconds: 1))) &&
              e.timestamp.isBefore(
                  filter.dateRange!.end.add(const Duration(milliseconds: 1))));
      return inCampaign && inRange;
    }).toList();
  }

  Kpis computeKpis({List<String>? forCampaignIds}) {
    final ids = (forCampaignIds == null || forCampaignIds.isEmpty)
        ? filteredCampaigns.map((c) => c.id).toSet()
        : forCampaignIds.toSet();

    final evs = filteredEvents.where((e) => ids.contains(e.campaignId));

    int convocados = 0,
        confirmados = 0,
        asistencia = 0,
        reacciones = 0,
        agendamientos = 0;
    for (final e in evs) {
      switch (e.type) {
        case EventType.invited:
          convocados++;
          break;
        case EventType.confirmed:
          confirmados++;
          break;
        case EventType.attended:
          asistencia++;
          break;
        case EventType.reaction:
          reacciones++;
          break;
        case EventType.scheduled:
          agendamientos++;
          break;
      }
    }
    final tasaNoShow =
        confirmados == 0 ? 0.0 : (confirmados - asistencia) / confirmados;
    return Kpis(
      convocados: convocados,
      confirmados: confirmados,
      asistencia: asistencia,
      tasaNoShow: tasaNoShow,
      reacciones: reacciones,
      agendamientos: agendamientos,
    );
  }

  Map<DateTime, Map<EventType, int>> dailySeries(
      {List<String>? forCampaignIds}) {
    final ids = (forCampaignIds == null || forCampaignIds.isEmpty)
        ? filteredCampaigns.map((c) => c.id).toSet()
        : forCampaignIds.toSet();
    final map = <DateTime, Map<EventType, int>>{};
    for (final e in filteredEvents.where((e) => ids.contains(e.campaignId))) {
      final d = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      map.putIfAbsent(
          d,
          () => {
                EventType.invited: 0,
                EventType.confirmed: 0,
                EventType.attended: 0,
                EventType.reaction: 0,
                EventType.scheduled: 0,
              });
      map[d]![e.type] = (map[d]![e.type] ?? 0) + 1;
    }
    return map;
  }
}

/// ======================
/// 4) SHELL con Provider
/// ======================

class StatsShell extends StatelessWidget {
  const StatsShell({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatsState(MockData.campaigns, MockData.events),
      child: const StatsPage(),
    );
  }
}

/// ======================
/// 5) PÁGINA PRINCIPAL (scrolleable)
/// ======================

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StatsState>();
    final kpis = state.computeKpis();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Campañas'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            icon: const Icon(Icons.table_view),
            onPressed: () => _exportCsv(context),
          ),
          IconButton(
            tooltip: 'Exportar PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportPdf(context),
          ),
        ],
      ),
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FiltersBar(),
            // KPIs
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _KpiCard(
                      title: 'Convocados',
                      value: kpis.convocados.toString(),
                      icon: Icons.campaign),
                  _KpiCard(
                      title: 'Confirmados',
                      value: kpis.confirmados.toString(),
                      icon: Icons.check_circle),
                  _KpiCard(
                      title: 'Asistencia',
                      value: kpis.asistencia.toString(),
                      icon: Icons.how_to_reg),
                  _KpiCard(
                      title: 'No-Show',
                      value: '${(kpis.tasaNoShow * 100).toStringAsFixed(1)}%',
                      icon: Icons.cancel_schedule_send),
                  _KpiCard(
                      title: 'Reacciones',
                      value: kpis.reacciones.toString(),
                      icon: Icons.favorite),
                  _KpiCard(
                      title: 'Agendamientos',
                      value: kpis.agendamientos.toString(),
                      icon: Icons.event_available),
                ],
              ),
            ),
            // Selector de gráfico (scroll horizontal para evitar overflow)
            const _ChartTypeBar(),
            const _ChartLegend(),
            // Área de gráfico con altura fija para funcionar dentro de un scroll
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                height: 300,
                child: const _ChartArea(),
              ),
            ),
            const _CompareStrip(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// ======================
/// 6) BARRA DE FILTROS
/// ======================

class _FiltersBar extends StatelessWidget {
  const _FiltersBar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StatsState>();
    final campaigns = state.allCampaigns;

    final types = {for (var c in campaigns) c.type}.toList()..sort();
    final locs = {for (var c in campaigns) c.location}.toList()..sort();
    final sts = {for (var c in campaigns) c.status}.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _Dropdown(
            label: 'Tipo',
            value: state.filter.type,
            items: ['(Todos)', ...types],
            onChanged: (v) =>
                _updateFilter(context, type: v == '(Todos)' ? null : v),
          ),
          const SizedBox(width: 8),
          _Dropdown(
            label: 'Lugar',
            value: state.filter.location,
            items: ['(Todos)', ...locs],
            onChanged: (v) =>
                _updateFilter(context, location: v == '(Todos)' ? null : v),
          ),
          const SizedBox(width: 8),
          _Dropdown(
            label: 'Estado',
            value: state.filter.status,
            items: ['(Todos)', ...sts],
            onChanged: (v) =>
                _updateFilter(context, status: v == '(Todos)' ? null : v),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(state.filter.dateRange == null
                ? 'Fechas (todas)'
                : '${DateFormat('dd/MM').format(state.filter.dateRange!.start)} – ${DateFormat('dd/MM').format(state.filter.dateRange!.end)}'),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 1),
                initialDateRange: state.filter.dateRange ??
                    DateTimeRange(
                        start: now.subtract(const Duration(days: 14)),
                        end: now),
              );
              _updateFilter(context, dateRange: picked);
            },
          ),
          const SizedBox(width: 8),
          const _CampaignMultiSelect(),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () =>
                context.read<StatsState>().setFilter(StatsFilter()),
            icon: const Icon(Icons.refresh),
            label: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _updateFilter(BuildContext ctx,
      {String? type,
      String? location,
      String? status,
      DateTimeRange? dateRange}) {
    final st = ctx.read<StatsState>();
    final f = st.filter;
    st.setFilter(StatsFilter(
      type: type ?? f.type,
      location: location ?? f.location,
      status: status ?? f.status,
      dateRange: dateRange ?? f.dateRange,
      selectedCampaignIds: f.selectedCampaignIds,
      compareMode: f.compareMode,
    ));
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Dropdown(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        DropdownButton<String>(
          value: value, // null => muestra hint
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
          onChanged: onChanged,
          hint: const Text('(Todos)'),
        ),
      ],
    );
  }
}

class _CampaignMultiSelect extends StatelessWidget {
  const _CampaignMultiSelect();

  @override
  Widget build(BuildContext context) {
    final st = context.watch<StatsState>();
    final all = st.allCampaigns;
    final selected = st.filter.selectedCampaignIds;

    return OutlinedButton.icon(
      icon: const Icon(Icons.filter_list),
      label: Text(selected.isEmpty
          ? 'Campañas (todas)'
          : 'Campañas: ${selected.length}'),
      onPressed: () async {
        final chosen = await showModalBottomSheet<List<String>>(
          context: context,
          builder: (ctx) {
            final temp = selected.toSet();
            return StatefulBuilder(
              builder: (ctx, setState) => SafeArea(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Selecciona 0..N (para comparar, elige 2)'),
                    ),
                    Expanded(
                      child: ListView(
                        children: all.map((c) {
                          final checked = temp.contains(c.id);
                          return CheckboxListTile(
                            title: Text(c.name),
                            subtitle:
                                Text('${c.type} • ${c.location} • ${c.status}'),
                            value: checked,
                            onChanged: (v) {
                              if (v == true)
                                temp.add(c.id);
                              else
                                temp.remove(c.id);
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            temp.clear();
                            setState(() {});
                          },
                          child: const Text('Limpiar'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, temp.toList()),
                          child: const Text('Aplicar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
        if (chosen != null) {
          st.setFilter(StatsFilter(
            type: st.filter.type,
            location: st.filter.location,
            status: st.filter.status,
            dateRange: st.filter.dateRange,
            selectedCampaignIds: chosen,
            compareMode: st.filter.compareMode,
          ));
        }
      },
    );
  }
}

/// ======================
/// 7) KPI CARDS (sin errores de layout/border)
/// ======================

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  const _KpiCard({required this.title, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 160, minHeight: 72),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: cs.outline.withOpacity(.3)), // borde uniforme ✅
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Franja de acento segura (alto fijo)
          SizedBox(
            width: 4,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, color: cs.primary),
            ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ======================
/// 8) Selector de tipo de gráfico (scroll horizontal)
/// ======================

class _ChartTypeBar extends StatelessWidget {
  const _ChartTypeBar();

  @override
  Widget build(BuildContext context) {
    final st = context.watch<StatsState>();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          const Center(child: Text('Tipo de gráfico:')),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Barras'),
            selected: st.chartType == ChartType.bar,
            onSelected: (_) => st.setChartType(ChartType.bar),
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('Líneas'),
            selected: st.chartType == ChartType.line,
            onSelected: (_) => st.setChartType(ChartType.line),
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('Dispersión'),
            selected: st.chartType == ChartType.scatter,
            onSelected: (_) => st.setChartType(ChartType.scatter),
          ),
        ],
      ),
    );
  }
}

/// ======================
/// 9) Leyenda
/// ======================

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    final st = context.watch<StatsState>();
    String text;
    switch (st.chartType) {
      case ChartType.bar:
        text = 'Confirmados (barras)';
        break;
      case ChartType.line:
        text = 'Asistencia (línea)';
        break;
      case ChartType.scatter:
        text = 'Asistencia (dispersión)';
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        children: [_LegendDot(text: text)],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String text;
  const _LegendDot({required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// ======================
/// 10) Área de gráfico (compat fl_chart 0.69.x)
/// ======================

class _ChartArea extends StatelessWidget {
  const _ChartArea();

  @override
  Widget build(BuildContext context) {
    final st = context.watch<StatsState>();
    final cs = Theme.of(context).colorScheme;
    final series = st.dailySeries();
    final dates = series.keys.toList()..sort();
    if (dates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, size: 48, color: cs.primary),
            const SizedBox(height: 8),
            const Text('Sin datos para los filtros seleccionados.'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Restablecer filtros'),
              onPressed: () =>
                  context.read<StatsState>().setFilter(StatsFilter()),
            ),
          ],
        ),
      );
    }

    final asistenciaPoints = <FlSpot>[];
    final confirmedBars = <BarChartGroupData>[];
    final scatterPoints = <ScatterSpot>[];

    for (int i = 0; i < dates.length; i++) {
      final d = dates[i];
      final a = (series[d]![EventType.attended] ?? 0).toDouble();
      final c = (series[d]![EventType.confirmed] ?? 0).toDouble();

      asistenciaPoints.add(FlSpot(i.toDouble(), a));
      confirmedBars.add(BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(toY: c, width: 14)],
      ));
      // fl_chart 0.69.x -> ScatterSpot solo acepta (x, y)
      scatterPoints.add(ScatterSpot(i.toDouble(), a));
    }

    switch (st.chartType) {
      case ChartType.line:
        return LineChart(LineChartData(
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: _datesSideTitles(dates)),
          ),
          lineBarsData: [
            LineChartBarData(
                spots: asistenciaPoints,
                isCurved: true,
                dotData: FlDotData(show: false)),
          ],
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ));
      case ChartType.bar:
        return BarChart(BarChartData(
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: _datesSideTitles(dates)),
          ),
          barGroups: confirmedBars,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ));
      case ChartType.scatter:
        return ScatterChart(ScatterChartData(
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: _datesSideTitles(dates)),
          ),
          scatterSpots: scatterPoints,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ));
    }
  }

  SideTitles _datesSideTitles(List<DateTime> dates) {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (value, meta) {
        final i = value.toInt();
        if (i < 0 || i >= dates.length) return const SizedBox.shrink();
        return Text(DateFormat('MM/dd').format(dates[i]),
            style: const TextStyle(fontSize: 10));
      },
      interval: 2,
    );
  }
}

/// ======================
/// 11) Comparación side-by-side
/// ======================

class _CompareStrip extends StatelessWidget {
  const _CompareStrip();

  @override
  Widget build(BuildContext context) {
    final st = context.watch<StatsState>();
    final selected = st.filter.selectedCampaignIds;
    final compareOn = st.filter.compareMode;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: const Border(top: BorderSide(color: Colors.black12)),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Switch(
                value: compareOn,
                onChanged: (v) {
                  st.setFilter(StatsFilter(
                    type: st.filter.type,
                    location: st.filter.location,
                    status: st.filter.status,
                    dateRange: st.filter.dateRange,
                    selectedCampaignIds: st.filter.selectedCampaignIds,
                    compareMode: v,
                  ));
                },
              ),
              const Text('Comparar (elige exactamente 2 campañas)'),
            ],
          ),
          if (compareOn)
            if (selected.length != 2)
              const Text('Selecciona 2 campañas en el filtro de campañas.',
                  style: TextStyle(color: Colors.red))
            else
              _CompareTable(campaignIds: selected),
        ],
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  final List<String> campaignIds;
  const _CompareTable({required this.campaignIds});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<StatsState>();
    final a = st.computeKpis(forCampaignIds: [campaignIds[0]]);
    final b = st.computeKpis(forCampaignIds: [campaignIds[1]]);

    double d(int x, int y) => (y - x) / (x == 0 ? 1.0 : x.toDouble()) * 100.0;
    double df(double x, double y) => (y - x) / (x == 0 ? 1.0 : x) * 100.0;

    final rows = [
      ['Convocados', a.convocados, b.convocados, d(a.convocados, b.convocados)],
      [
        'Confirmados',
        a.confirmados,
        b.confirmados,
        d(a.confirmados, b.confirmados)
      ],
      ['Asistencia', a.asistencia, b.asistencia, d(a.asistencia, b.asistencia)],
      [
        'No-Show %',
        (a.tasaNoShow * 100).toStringAsFixed(1) + '%',
        (b.tasaNoShow * 100).toStringAsFixed(1) + '%',
        df(a.tasaNoShow, b.tasaNoShow)
      ],
      ['Reacciones', a.reacciones, b.reacciones, d(a.reacciones, b.reacciones)],
      [
        'Agendamientos',
        a.agendamientos,
        b.agendamientos,
        d(a.agendamientos, b.agendamientos)
      ],
    ];

    final cA = st.allCampaigns.firstWhere((c) => c.id == campaignIds[0]).name;
    final cB = st.allCampaigns.firstWhere((c) => c.id == campaignIds[1]).name;

    final table = Table(
      columnWidths: const {
        0: FixedColumnWidth(140),
        1: FixedColumnWidth(100),
        2: FixedColumnWidth(100),
        3: FixedColumnWidth(90),
      },
      border: TableBorder.all(color: Colors.black12),
      children: [
        const TableRow(children: [
          _Cell.bold('KPI'),
          _Cell.bold('A'),
          _Cell.bold('B'),
          _Cell.bold('Δ% (B vs A)'),
        ]),
        ...rows.map((r) => TableRow(children: [
              _Cell('${r[0]}'),
              _Cell('${r[1]}'),
              _Cell('${r[2]}'),
              _DeltaCell(r[3] is double ? r[3] as double : 0.0),
            ])),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$cA  vs  $cB',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Scroll horizontal por si no cabe
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: table,
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool isBold;
  const _Cell(this.text, {this.isBold = false});
  const _Cell.bold(this.text) : isBold = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Text(text,
          style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
    );
  }
}

class _DeltaCell extends StatelessWidget {
  final double deltaPercent;
  const _DeltaCell(this.deltaPercent);

  @override
  Widget build(BuildContext context) {
    final s =
        '${deltaPercent >= 0 ? '+' : ''}${deltaPercent.toStringAsFixed(1)}%';
    final col = deltaPercent >= 0 ? Colors.green : Colors.red;
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Text(s, style: TextStyle(color: col, fontWeight: FontWeight.w600)),
    );
  }
}

/// ======================
/// 12) Exportar CSV y PDF (funciona Web y móvil)
/// ======================

Future<void> _exportCsv(BuildContext context) async {
  try {
    final st = context.read<StatsState>();
    final campaigns = st.filteredCampaigns;
    final rows = <List<dynamic>>[];

    rows.add([
      'Corte',
      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      'Tipo',
      st.filter.type ?? '(Todos)',
      'Lugar',
      st.filter.location ?? '(Todos)',
      'Estado',
      st.filter.status ?? '(Todos)',
      'FechaDesde',
      st.filter.dateRange?.start.toIso8601String() ?? '',
      'FechaHasta',
      st.filter.dateRange?.end.toIso8601String() ?? '',
    ]);
    rows.add([
      'Campaña',
      'Convocados',
      'Confirmados',
      'Asistencia',
      'NoShow%',
      'Reacciones',
      'Agendamientos'
    ]);

    for (final c in campaigns) {
      final k = st.computeKpis(forCampaignIds: [c.id]);
      rows.add([
        c.name,
        k.convocados,
        k.confirmados,
        k.asistencia,
        (k.tasaNoShow * 100).toStringAsFixed(1),
        k.reacciones,
        k.agendamientos
      ]);
    }

    final csvStr = const ListToCsvConverter().convert(rows);
    final filename =
        'estadisticas_${DateTime.now().millisecondsSinceEpoch}.csv';

    if (kIsWeb) {
      // Descarga directa en navegador
      final bytes = utf8.encode(csvStr);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final a = html.AnchorElement(href: url)
        ..download = filename
        ..style.display = 'none';
      html.document.body?.append(a);
      a.click();
      a.remove();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV descargado')),
      );
      return;
    }

    // Móvil/desktop
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csvStr);
    await Share.shareXFiles([XFile(file.path)], text: 'Export CSV');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al exportar CSV: $e')),
    );
  }
}

Future<void> _exportPdf(BuildContext context) async {
  try {
    final st = context.read<StatsState>();
    final pdf = pw.Document();
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final campaigns = st.filteredCampaigns;

    pdf.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Text('Estadísticas de Campañas',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Corte: ${df.format(DateTime.now())}'),
          pw.Text('Filtros: Tipo=${st.filter.type ?? "(Todos)"} '
              'Lugar=${st.filter.location ?? "(Todos)"} '
              'Estado=${st.filter.status ?? "(Todos)"} '
              'Fechas=${st.filter.dateRange == null ? "(todas)" : "${DateFormat('dd/MM').format(st.filter.dateRange!.start)}–${DateFormat('dd/MM').format(st.filter.dateRange!.end)}"}'),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {0: const pw.FlexColumnWidth(3)},
            children: [
              pw.TableRow(children: [
                _p('Campaña', bold: true),
                _p('Conv.', bold: true),
                _p('Conf.', bold: true),
                _p('Asist.', bold: true),
                _p('NoShow %', bold: true),
                _p('Reacc.', bold: true),
                _p('Agend.', bold: true),
              ]),
              ...campaigns.map((c) {
                final k = st.computeKpis(forCampaignIds: [c.id]);
                return pw.TableRow(children: [
                  _p(c.name),
                  _p('${k.convocados}'),
                  _p('${k.confirmados}'),
                  _p('${k.asistencia}'),
                  _p('${(k.tasaNoShow * 100).toStringAsFixed(1)}'),
                  _p('${k.reacciones}'),
                  _p('${k.agendamientos}'),
                ]);
              }),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final filename =
        'estadisticas_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (kIsWeb) {
      // Descarga directa en Web
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final a = html.AnchorElement(href: url)
        ..download = filename
        ..style.display = 'none';
      html.document.body?.append(a);
      a.click();
      a.remove();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF descargado')),
      );
      return;
    }

    // Móvil/desktop
    await Printing.sharePdf(bytes: bytes, filename: filename);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al exportar PDF: $e')),
    );
  }
}

pw.Widget _p(String s, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(s,
        style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)));
