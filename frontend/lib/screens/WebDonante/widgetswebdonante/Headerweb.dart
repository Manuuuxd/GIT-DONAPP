import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart';
import 'package:donapp_android/screens/avatar/avatar_service.dart';
import 'package:donapp_android/screens/avatar/avatar_model.dart';
import 'package:donapp_android/screens/avatar/avatar_preview.dart';
import 'package:donapp_android/screens/WebDonante/perfil_donante.dart';

import '../../home/home_controller.dart';

class HomeHeaderweb extends StatefulWidget {
  final HomeController controller;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onHomePressed;

  const HomeHeaderweb({
    super.key,
    required this.controller,
    this.onProfilePressed,
    this.onHomePressed,
  });

  @override
  State<HomeHeaderweb> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeaderweb> {
  AvatarData? _avatar;
  bool _loadingAvatar = true;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final loaded = await AvatarService.load();
    if (!mounted) return;
    setState(() {
      _avatar = loaded;
      _loadingAvatar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [?AppColors.customRed[200], const Color(0xFF4AB5E3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onHomePressed,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6), // reduce el header
                  child: Transform.scale(
                    scale: 0.9, // ajusta entre 0.7 y 0.9 según se vea mejor
                    child: Image.asset(
                      'assets/images/Icono.png',
                      height: 80, // o 60 si quieres más compacto
                      filterQuality: FilterQuality.high, // mejora nitidez
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/homedash');
            },
            child: const Text(
              "Hogar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
        if (controller.isLoggedIn)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PerfilUsuarioModern(),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), // fondo suave
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      controller.userName ?? "Usuario",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _loadingAvatar
                        ? const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : _avatar != null
                        ? CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.transparent,
                      child: AvatarPreview(data: _avatar!, size: 44),
                    )
                        : const CircleAvatar(
                      backgroundImage:
                      AssetImage('assets/images/avatar3.png'),
                      radius: 20,
                    ),
                  ],
                ),
              ),
            ),
          )
          else
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login, size: 18),
              label: const Text("Iniciar sesión"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.customBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
