import 'package:flutter/material.dart';
import 'seleccionar_encuesta_screen.dart';

void main() {
  runApp(EncuestaApp());
}

class EncuestaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Definimos un tema base que puede ser adaptado por el sistema
    return MaterialApp(
      title: 'Encuestas DonApp',
      theme: ThemeData(
        // Usamos la configuración de color predeterminada, que se adapta al modo claro/oscuro
        // La eliminamos: scaffoldBackgroundColor: Color(0xFFF5F5F5), 
        // La eliminamos: primaryColor: Color(0xFFB20000), 
        useMaterial3: true,
        // Definimos un esquema de color para forzar los colores primarios y secundarios
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.red, // Rojo para primario
          accentColor: const Color(0xFF00AEEF), // Celeste Donapp para acento/secundario
          backgroundColor: const Color(0xFFF5F5F5), // Fondo claro
          cardColor: Colors.white,
        ).copyWith(
          // Definiciones clave para modo oscuro:
          primary: const Color(0xFFB20000), // Rojo principal (Donapp Red)
          onPrimary: Colors.white,
          secondary: const Color(0xFF00AEEF), // Celeste (Donapp Blue)
          onSecondary: Colors.white,
          error: Colors.red,
          // onBackground y onSurface se adaptarán automáticamente.
        ),
        
        appBarTheme: const AppBarTheme(
          // Ahora hereda el color de fondo del ColorScheme.primary y foregroundColor del ColorScheme.onPrimary
          // Si queremos un color neutro, usamos el ColorScheme.background
          backgroundColor: Colors.transparent, // Transparente para usar el color de Scaffold
          foregroundColor: Colors.black, // Color inicial, será sobreescrito por el Scaffold
          elevation: 0,
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          // Ahora usa los colores de ColorScheme.primary y ColorScheme.onPrimary
          style: ElevatedButton.styleFrom(
            // Eliminado: backgroundColor: Color(0xFF00AEEF), 
            // Eliminado: foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
        // CORRECCIÓN APLICADA AQUÍ (Línea 56)
        cardTheme: CardThemeData(
          // Ahora usa el color de Card del ColorScheme
          // Eliminado: color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        // Eliminado: theme de texto
        // textTheme: TextTheme(
        //   bodyLarge: TextStyle(color: Color(0xFF333333)), // Gris grafito
        //   bodyMedium: TextStyle(color: Color(0xFF333333)),
        // ),
      ),
      // Añadimos el tema oscuro que se aplicará automáticamente
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB20000),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFE57373), // Rojo más brillante para oscuro
          onPrimary: Colors.black,
          secondary: const Color(0xFF81D4FA), // Celeste más brillante para oscuro
          surface: Colors.grey[900], // Fondo de tarjetas/elementos
          onSurface: Colors.white70,
        ),
        // CORRECCIÓN APLICADA AQUÍ (Línea 89)
        cardTheme: CardThemeData(
          color: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
      themeMode: ThemeMode.system, // Usa la configuración del sistema
      home: SeleccionarEncuestaScreen(),
    );
  }
}