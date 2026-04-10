import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;


class Ubicacion {
  final String region;
  final String provincia;
  final String comuna;

  Ubicacion(this.region, this.provincia, this.comuna);

  Future<List<Ubicacion>> cargarUbicaciones() async {
    final data = await rootBundle.load('assets/ubicaciones.xlsx');
    final bytes = data.buffer.asUint8List();
    final excel = Excel.decodeBytes(bytes);

    List<Ubicacion> ubicaciones = [];

    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows.skip(1)) {
        final region = row[2]?.value.toString() ?? '';
        final provincia = row[1]?.value.toString() ?? '';
        final comuna = row[0]?.value.toString() ?? '';
        ubicaciones.add(Ubicacion(region, provincia, comuna));
      }
    }

    return ubicaciones;
  }
}