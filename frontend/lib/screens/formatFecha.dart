String formatFecha(String? fecha) {
  if (fecha == null) return 'N/A';
  try {
    final parsedDate = DateTime.parse(fecha);
    return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
  } catch (_) {
    return 'N/A';
  }
}