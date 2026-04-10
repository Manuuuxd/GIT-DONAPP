class User {
  final int id;
  final String username;
  final String email;
  final UserProfile? profile;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'])
          : null,
    );
  }
}

class UserProfile {
  final int id;
  final String? nombre;
  final String? sexo;
  final bool? aptoParaDonar;
  final String? region;
  final String? provincia;
  final String? comuna;
  final String? fechaUltimaDonacion;
  final int? xp;
  final int? nivel;
  final String? nombreNivel;
  final String? proximaDonacion;
  final int? userId;
  final String? tipoSangre;

  UserProfile({
    required this.id,
    this.nombre,
    this.sexo,
    this.aptoParaDonar,
    this.region,
    this.provincia,
    this.comuna,
    this.fechaUltimaDonacion,
    this.xp,
    this.nivel,
    this.nombreNivel,
    this.proximaDonacion,
    this.userId,
    this.tipoSangre,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      nombre: json['nombre'],
      sexo: json['sexo'],
      aptoParaDonar: json['apto_para_donar'],
      region: json['region'],
      provincia: json['provincia'],
      comuna: json['comuna'],
      fechaUltimaDonacion: json['fecha_ultima_donacion'],
      xp: json['xp'],
      nivel: json['nivel'],
      nombreNivel: json['nombre_nivel'],
      proximaDonacion: json['proxima_donacion'],
      userId: json['user_id'],
      tipoSangre: json['tipo_sangre'],
    );
  }
}
