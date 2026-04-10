class BloodCompatibility {
  static const types = [
    'O−', 'O+', 'A−', 'A+', 'B−', 'B+', 'AB−', 'AB+',
  ];

  // Tabla simplificada: por receptor, lista de donantes válidos
  static const Map<String, List<String>> _recipientAccepts = {
    'O−': ['O−'],
    'O+': ['O−', 'O+'],
    'A−': ['O−', 'A−'],
    'A+': ['O−', 'O+', 'A−', 'A+'],
    'B−': ['O−', 'B−'],
    'B+': ['O−', 'O+', 'B−', 'B+'],
    'AB−': ['O−', 'A−', 'B−', 'AB−'],
    'AB+': ['O−', 'O+', 'A−', 'A+', 'B−', 'B+', 'AB−', 'AB+'],
  };

  /// Normalize string to use the same minus sign
  static String normalize(String type) {
    return type
        .replaceAll('-', '−') // ensure Unicode minus
        .replaceAll('–', '−') // in case en dash sneaks in
        .trim();
  }

  static bool canDonate(String donor, String recipient) {
    final d = normalize(donor);
    final r = normalize(recipient);
    final accepts = _recipientAccepts[r];
    return accepts?.contains(d) ?? false;
  }
  static String explain(String donor, String recipient) {
    if (canDonate(donor, recipient)) {
      return '$donor puede donar a $recipient por compatibilidad conocida.';
    }
    final d = normalize(donor);
    final r = normalize(recipient);
    if (canDonate(d, r)) {
      return '$d puede donar a $r por compatibilidad conocida.';
    }
    // Explicación textual básica
    final donorRhPos = donor.contains('+');
    final recRhPos = recipient.contains('+');
    final donorBase = donor.replaceAll(RegExp('[+−-]'), '');
    final recBase = recipient.replaceAll(RegExp('[+−-]'), '');

    String reason = '';
    if (donorRhPos && !recRhPos) {
      reason += 'El factor Rh positivo del donante puede causar reacción en un receptor Rh negativo. ';
    }
    if (donorBase != 'O' && recBase == 'O') {
      reason += 'Los receptores tipo O solo aceptan glóbulos rojos tipo O. ';
    }
    if (donorBase == 'A' && recBase == 'B') {
      reason += 'Antígenos A no compatibles con receptores tipo B. ';
    } else if (donorBase == 'B' && recBase == 'A') {
      reason += 'Antígenos B no compatibles con receptores tipo A. ';
    }
    if (reason.isEmpty) {
      reason = 'Las reglas ABO/Rh no permiten esta combinación.';
    }
    return reason;
  }

  static List<List<String>> keyCompatibilityRows() {
    return [
      ['Receptor', 'Donantes válidos'],
      ..._recipientAccepts.entries.map((e) => [e.key, e.value.join(', ')]),
    ];
  }
}
