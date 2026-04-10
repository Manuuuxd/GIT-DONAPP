import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:donapp_android/colours/app_colors.dart';
import 'package:donapp_android/screens/gamificacion/gamification_service.dart';
import 'package:donapp_android/screens/gamificacion/gm_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:donapp_android/screens/Usuario/otorgar_logro.dart';
import 'package:donapp_android/screens/Usuario/handle_item.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  final List<Map<String, String>> images = const [
    {'url': 'https://i.postimg.cc/grQgJKCz/Plantilla1.png', 'label': 'Plantilla 1'},
    {'url': 'https://i.postimg.cc/vcn36VyW/Plantilla2.png', 'label': 'Plantilla 2'},
    {'url': 'https://i.postimg.cc/TKXQj32B/Plantilla3.png', 'label': 'Plantilla 3'},
  ];

  Future<void> _shareToPlatform(BuildContext context, String imageUrl, String platform) async {
    late final Uri shareUri;

    switch (platform) {
      case 'facebook':
        final quote = Uri.encodeComponent('🎉 ¡Mira mis logros en DonApp!');
        shareUri = Uri.parse(
            'https://www.facebook.com/sharer/sharer.php?u=$imageUrl&quote=$quote');
        break;
      case 'twitter':
        final tweet = Uri.encodeComponent('🎉 ¡Mira mis logros en DonApp!');
        shareUri =
            Uri.parse('https://twitter.com/intent/tweet?text=$tweet&url=$imageUrl');
        break;
      case 'whatsapp':
        final waText =
            Uri.encodeComponent('🎉 ¡Mira mis logros en DonApp! $imageUrl');
        shareUri = Uri.parse('https://wa.me/?text=$waText');
        break;
      default:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Plataforma no soportada")),
          );
        }
        return;
    }

    try {
      await launchUrlString(shareUri.toString(),
          mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo abrir la app o navegador: $e")),
        );
      }
    }
  }

  void _showPlatformPicker(BuildContext context, String imageUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.facebook, color: AppColors.customBlue[700]),
                title: const Text("Compartir en Facebook"),
                onTap: () {
                  Navigator.pop(context);
                  _shareToPlatform(context, imageUrl, 'facebook');
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: AppColors.customBlue[600]),
                title: const Text("Compartir en X (Twitter)"),
                onTap: () {
                  Navigator.pop(context);
                  _shareToPlatform(context, imageUrl, 'twitter');
                },
              ),
              const Divider(height: 0, color: AppColors.borderOutline),
              ListTile(
                leading: const Icon(Icons.chat, color: AppColors.success),
                title: const Text("Compartir en WhatsApp"),
                onTap: () {
                  Navigator.pop(context);
                  _shareToPlatform(context, imageUrl, 'whatsapp');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchGamificationProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: Text('No hay datos de gamificación disponibles'),
            ),
          );
        }

        final gamificationData = snapshot.data!;
        final xp = gamificationData['xp'] ?? 0;
        final streak = gamificationData['streak'] ?? 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.background,
            iconTheme: const IconThemeData(color: AppColors.onBackground),
            title: const Text(
              "Comparte tus logros",
              style: TextStyle(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Indicadores de gamificación
                XpPill(xp: xp),
                const SizedBox(height: 8),
                StreakPill(days: streak),
                const SizedBox(height: 16),

                // Cuadrícula de imágenes
                Expanded(
                  child: GridView.builder(
                    itemCount: images.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final img = images[index];
                      return GestureDetector(
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('authToken') ?? '';
                          try {
                            final respuesta =
                                await otorgarLogro(token, 'amigo_invitado');
                            mostrarDialogoLogro(context, respuesta);

                            final recibo = await otorgarItem('xp_pequeño',
                                cantidad: 1);
                            if (recibo['status'] == 'item_otorgado' &&
                                context.mounted) {
                              await showItemDialog(
                                context,
                                title: '¡Ítem otorgado!',
                                message: 'Has recibido: XP pequeño',
                                imageAssetPath:
                                    'assets/images/items/xp_pequeño.png',
                              );
                            }

                            _showPlatformPicker(context, img['url']!);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Ha ocurrido un error. $e')),
                              );
                            }
                          }
                        },
                        child: Card(
                          color: AppColors.surface,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                                color: AppColors.borderOutline),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(img['url']!, fit: BoxFit.cover),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.background.withOpacity(0.0),
                                        AppColors.background.withOpacity(0.75),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.customBlue[50],
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                        color: AppColors.borderOutline),
                                  ),
                                  child: Text(
                                    img['label'] ?? '',
                                    style: TextStyle(
                                      color: AppColors.customBlue[700],
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 10,
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.borderOutline),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => _showPlatformPicker(
                                        context, img['url']!),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.ios_share_rounded,
                                            size: 18,
                                            color: AppColors.customBlue[700]),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Compartir",
                                          style: TextStyle(
                                            color: AppColors.customBlue[700],
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: .2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // Método para obtener el progreso de gamificación
  Future<Map<String, int>> _fetchGamificationProgress() async {
    final xp = await Gamification.xp();
    final streak = await Gamification.streak();
    return {
      'xp': xp,
      'streak': streak,
    };
  }
}
