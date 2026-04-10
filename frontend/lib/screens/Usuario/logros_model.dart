class Achievement {
  final int id;
  final String name;
  final String description;
  final String iconUrl;
  final int requiredCount;
  final bool unlocked;
  final int currentCount;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.requiredCount,
    required this.unlocked,
    required this.currentCount,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
      requiredCount: json['required_count'],
      unlocked: json['unlocked'],
      currentCount: json['current_count'],
    );
  }
}
