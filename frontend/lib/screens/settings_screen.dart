// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:donapp_android/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Consume el provider para saber el estado actual
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Función de ayuda para crear los Radio Tiles modernos
    Widget _buildRadioTile(String title, String subtitle, ThemeMode value) {
      return ListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
        // Hacemos que toda la fila sea "clicable"
        onTap: () => themeProvider.setTheme(value),
        trailing: Radio<ThemeMode>(
          // Este es el widget de Radio
          value: value,
          // 'groupValue' aquí es correcto y no está obsoleto
          groupValue: themeProvider.themeMode,
          onChanged: (newValue) {
            if (newValue != null) {
              themeProvider.setTheme(newValue);
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Tema de la aplicación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary, // Usa el color del tema
              ),
            ),
          ),
          // (CA01) Opciones de Tema
          _buildRadioTile(
            'Claro',
            'Usar siempre el tema claro',
            ThemeMode.light,
          ),
          _buildRadioTile(
            'Oscuro',
            'Usar siempre el tema oscuro',
            ThemeMode.dark,
          ),
          _buildRadioTile(
            'Automático (Sistema)',
            'Seguir la configuración de tu dispositivo',
            ThemeMode.system,
          ),
        ],
      ),
    );
  }
}