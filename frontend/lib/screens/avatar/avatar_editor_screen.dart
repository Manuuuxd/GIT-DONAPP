import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart';
import 'package:donapp_android/screens/avatar/avatar_model.dart';
import 'package:donapp_android/screens/avatar/avatar_service.dart';
import 'package:donapp_android/screens/avatar/avatar_preview.dart';

class AvatarEditorScreen extends StatefulWidget {
  const AvatarEditorScreen({super.key});

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  AvatarData _data = const AvatarData(
    skinColor: Color(0xFFF4D1B5),
    shirtColor: Color(0xFF4DA1E5),
    accessory: Accessory.none,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await AvatarService.load();
    if (!mounted) return;
    setState(() => _data = loaded);
  }

  Future<void> _save() async {
    await AvatarService.save(_data);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar guardado')),
    );
    Navigator.pop(context, true); // volver al perfil
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tu Avatar'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: AvatarPreview(data: _data, size: 180)),
          const SizedBox(height: 16),
          _SectionTitle('Piel'),
          _ColorRow(
            colors: const [
              Color(0xFFF4D1B5),
              Color(0xFFEEC39F),
              Color(0xFFD9A37C),
              Color(0xFFB87D59),
              Color(0xFF8C5A3B),
            ],
            selected: _data.skinColor,
            onTap: (c) => setState(() => _data = _data.copyWith(skinColor: c)),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Camiseta'),
          _ColorRow(
            colors: [
              AppColors.customBlue[300]!,
              AppColors.customBlue[400]!,
              AppColors.customBlue[700]!,
              AppColors.customRed[400]!,
              AppColors.grey[600]!,
            ],
            selected: _data.shirtColor,
            onTap: (c) => setState(() => _data = _data.copyWith(shirtColor: c)),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Accesorio'),
          _AccessoryRow(
            value: _data.accessory,
            onChanged: (a) => setState(() => _data = _data.copyWith(accessory: a)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.customBlue[700],
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _save,
            icon: const Icon(Icons.check, color: AppColors.white),
            label: const Text('Guardar cambios', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.customBlue[700],
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onTap;

  const _ColorRow({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((c) {
        final isSel = c.value == selected.value;
        return GestureDetector(
          onTap: () => onTap(c),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSel ? AppColors.customBlue[700]! : AppColors.borderOutline,
                width: isSel ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AccessoryRow extends StatelessWidget {
  final Accessory value;
  final ValueChanged<Accessory> onChanged;

  const _AccessoryRow({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(Accessory a, String label, IconData icon) {
      final sel = value == a;
      return ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: sel,
        onSelected: (_) => onChanged(a),
        selectedColor: AppColors.customBlue[100],
        labelStyle: TextStyle(
          color: sel ? AppColors.customBlue[800] : AppColors.onBackground,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        chip(Accessory.none, 'Ninguno', Icons.block),
        chip(Accessory.cap, 'Gorro', Icons.hiking), // icono representativo
        chip(Accessory.glasses, 'Lentes', Icons.remove_red_eye),
        chip(Accessory.cape, 'Capa', Icons.emoji_people),
      ],
    );
  }
}