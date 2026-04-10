class ApiConfig {

  static const String? envBaseUrl = String.fromEnvironment('BASE_URL');

  // Esto es lo que detecta si es web
  static bool get isWeb => identical(0, 0.0);

  // Decide which base URL to use
  static String get baseUrl {
    if (envBaseUrl != null && envBaseUrl!.isNotEmpty) {
      return envBaseUrl!;
    }
    if (isWeb) return 'https://midonapp.cl';

    return 'https://midonapp.cl';
  }

  // Helper to build endpoints
  static String endpoint(String path) => '$baseUrl/$path';
}