import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart';

class XpPill extends StatelessWidget {
  final int xp;
  const XpPill({super.key, required this.xp});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.customBlue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOutline),
      ),
      child: Row(children: [
        Icon(Icons.star, size: 14, color: AppColors.customBlue[700]),
        const SizedBox(width: 6),
        Text('$xp XP', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.customBlue[700])),
      ]),
    );
  }
}

class StreakPill extends StatelessWidget {
  final int days;
  const StreakPill({super.key, required this.days});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOutline),
      ),
      child: Row(children: [
        const Text('🔥', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text('${days}d racha', style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class QuestBanner extends StatelessWidget {
  final String text;
  final String cta;
  final VoidCallback onTap;
  const QuestBanner({super.key, required this.text, required this.cta, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.customBlue[50],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderOutline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.flag_rounded, color: AppColors.customBlue[700], size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.customBlue[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(cta, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DonorProgress extends StatelessWidget {
  final int current;
  final int target;
  const DonorProgress({super.key, required this.current, required this.target});
  @override
  Widget build(BuildContext context) {
    final ratio = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: ratio,
          color: AppColors.customBlue[700],
          backgroundColor: AppColors.surface2,
          minHeight: 6,
        ),
        const SizedBox(height: 6),
        Text('$current / $target donantes', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}