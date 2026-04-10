# DonApp - Aplicación Flutter para Donación de Sangre

DonApp es una aplicación móvil desarrollada en Flutter que permite evaluar la elegibilidad de una persona para donar sangre, registrar usuarios y mantener sesiones.

## 📦 Requisitos

Antes de ejecutar la app, asegúrate de tener instalado:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) o [Visual Studio Code](https://code.visualstudio.com/)
- Emulador de Android o dispositivo físico
- Servidor Backend corriendo (Django REST API)

## ⚙️ Instalación

1. Clona este repositorio:

```bash
git clone https://github.com/Jmanzano/DonApp.git
#esta es la rama master, por ende se debe de descargar la rama master y ejecutar esto después de hacer funcionar el backend.
cd donapp
```
2. Instala las dependencias
    flutter pub get
3. Conecta un dispositivo físico o inicia un emulador:

    flutter devices
0
4. Ejecuta la aplicación:
   flutter run
      Se puede ejecutar en modo web con:
         flutter run -d chrome
Comandos utiles para flutter:
5. | Acción                             | Comando                   |
   | ---------------------------------- | ------------------------- |
   | Obtener dependencias               | `flutter pub get`         |
   | Limpiar el proyecto                | `flutter clean`           |
   | Ver dispositivos disponibles       | `flutter devices`         |
   | Ejecutar en un dispositivo         | `flutter run`             |
   | Ver errores y solución automática  | `flutter doctor`          |
   | Compilar APK                       | `flutter build apk`       |
   | Compilar AppBundle para Play Store | `flutter build appbundle` |

## Para ejecutar la app de DONANTE:

flutter run --flavor donante --target lib/main_donante.dart

## Para ejecutar la app de ADMIN:

flutter run --flavor admin --target lib/main_admin.dart

a. Compilar APKs (para pruebas o instalación manual)

## APK de DONANTE:

flutter build apk --flavor donante --target lib/main_donante.dart


## APK de ADMIN:

flutter build apk --flavor admin --target lib/main_admin.dart
