
import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart';
import 'avatar_model.dart';

class AvatarPreview extends StatelessWidget {
  final AvatarData data;
  final double size;

  const AvatarPreview({
    super.key,
    required this.data,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    final headSize = size * 0.45;
    final bodyHeight = size * 0.35;
    final bodyWidth = size * 0.62;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Cape (capa) detrás del cuerpo
          if (data.accessory == Accessory.cape)
            Positioned(
              top: size * 0.35,
              child: Container(
                width: bodyWidth * 1.1,
                height: bodyHeight * 1.1,
                decoration: BoxDecoration(
                  color: AppColors.customBlue[100],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

          // Body (camiseta)
          Positioned(
            top: size * 0.45,
            child: Container(
              width: bodyWidth,
              height: bodyHeight,
              decoration: BoxDecoration(
                color: data.shirtColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderOutline),
              ),
            ),
          ),

          // Head
          Positioned(
            top: size * 0.12,
            child: Container(
              width: headSize,
              height: headSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.skinColor,
                border: Border.all(color: AppColors.borderOutline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
            ),
          ),

          // Cap (gorro) arriba de la cabeza
          if (data.accessory == Accessory.cap)
            Positioned(
              top: size * 0.08,
              child: Container(
                width: headSize * 0.9,
                height: headSize * 0.45,
                decoration: BoxDecoration(
                  color: AppColors.customBlue[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: AppColors.borderOutline),
                ),
              ),
            ),

          // Glasses (lentes) sobre la cara
          if (data.accessory == Accessory.glasses)
            Positioned(
              top: size * 0.22,
              child: _Glasses(width: headSize * 0.8),
            ),
        ],
      ),
    );
  }
}

class _Glasses extends StatelessWidget {
  final double width;
  const _Glasses({required this.width});

  @override
  Widget build(BuildContext context) {
    final lensSize = width * 0.38;
    final bridgeWidth = width * 0.12;
    final frameColor = AppColors.eerieBlack;

    return Row(
      children: [
        _lens(lensSize, frameColor),
        SizedBox(width: bridgeWidth),
        _lens(lensSize, frameColor),
      ],
    );
  }

  Widget _lens(double size, Color color) {
    return Container(
      width: size,
      height: size * 0.72,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withOpacity(.1),
      ),
    );
  }
}
