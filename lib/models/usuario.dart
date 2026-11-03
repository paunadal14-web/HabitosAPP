class Usuario {
  final int? id;
  final String usuario;
  final String nombre;
  final String apellidos;
  final String email;
  final String fechaCreacion;
  final String rol;

  Usuario({
    this.id,
    required this.usuario,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.fechaCreacion,
    this.rol = 'usuario',
  });

  bool get esAdministrador => rol == 'administrador';

  Map<String, Object?> toMap() {
    return {
      'usuario': usuario.trim(),
      'nombre': nombre.trim(),
      'apellidos': apellidos.trim(),
      'email': email.trim(),
      'fecha_creacion': fechaCreacion,
      'rol': rol,
    };
  }

  factory Usuario.fromMap(Map<String, Object?> datos) {
    return Usuario(
      id: datos['id'] as int,
      usuario: datos['usuario'] as String,
      nombre: datos['nombre'] as String,
      apellidos: datos['apellidos'] as String,
      email: datos['email'] as String,
      fechaCreacion: datos['fecha_creacion'] as String,
      rol: datos['rol'] as String,
    );
  }
}
