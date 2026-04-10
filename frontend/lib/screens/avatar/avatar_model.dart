import 'dart:convert';
import 'package:flutter/material.dart';

enum Accessory { none, cap, glasses, cape }

class AvatarData {
  final Color skinColor;
  final Color shirtColor;
  final Accessory accessory;

  const AvatarData({
    required this.skinColor,
    required this.shirtColor,
    required this.accessory,
  });

  AvatarData copyWith({
    Color? skinColor,
    Color? shirtColor,
    Accessory? accessory,
  }) {
    return AvatarData(
      skinColor: skinColor ?? this.skinColor,
      shirtColor: shirtColor ?? this.shirtColor,
      accessory: accessory ?? this.accessory,
    );
    }

  Map<String, dynamic> toMap() => {
        'skinColor': skinColor.value,
        'shirtColor': shirtColor.value,
        'accessory': accessory.name,
      };

  factory AvatarData.fromMap(Map<String, dynamic> map) {
    return AvatarData(
      skinColor: Color(map['skinColor'] as int),
      shirtColor: Color(map['shirtColor'] as int),
      accessory: Accessory.values.firstWhere(
        (a) => a.name == map['accessory'],
        orElse: () => Accessory.none,
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AvatarData.fromJson(String source) =>
      AvatarData.fromMap(jsonDecode(source) as Map<String, dynamic>);
}