class Appointment {
  final String rut;
  final String email;
  final String date;
  final String time;
  final int centerId; // centro elegido

  Appointment({
    required this.rut,
    required this.email,
    required this.date,
    required this.time,
    required this.centerId,
  });

  Map<String, dynamic> toJson() => {
    "rut": rut,
    "email": email,
    "date": date,
    "time": time,
    "center_id": centerId,
  };
}
