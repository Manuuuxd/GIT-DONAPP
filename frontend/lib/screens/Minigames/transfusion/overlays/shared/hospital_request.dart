

class HospitalRequest {
  final String bloodType;
  final int unitsNeeded;
  final Duration duration;
  DateTime createdAt;

  HospitalRequest({
    required this.bloodType,
    this.unitsNeeded = 1,
    this.duration = const Duration(seconds: 10),
  }) : createdAt = DateTime.now();

}