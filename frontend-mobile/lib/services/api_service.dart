
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
 static const String baseUrl = 'http://192.168.1.8:7001';
  // Comprobar la conexión con el backend.
  static Future<bool> comprobarBackend() async {
    try {
      final respuesta = await http
          .get(Uri.parse('$baseUrl/api/v1/health'))
          .timeout(const Duration(seconds: 5));

      if (respuesta.statusCode != 200) return false;

      final datos = jsonDecode(respuesta.body);
      return datos['estado'] == 'disponible';
    } catch (_) {
      return false;
    }
  }

  // Iniciar sesión.
  static Future<Map<String, dynamic>> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final respuesta = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'correo': correo.trim(),
              'contrasena': contrasena,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final datos = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200) {
        return {
          'exito': true,
          'mensaje': datos['mensaje'] ?? 'Inicio de sesión exitoso',
          'usuario': datos['usuario'],
        };
      }

      return {
        'exito': false,
        'mensaje': datos['error'] ?? 'Correo o contraseña incorrectos',
      };
    } catch (_) {
      return {
        'exito': false,
        'mensaje': 'No se pudo conectar con el servidor.',
      };
    }
  }

  // Consultar los equipos registrados en la base de datos.
  static Future<List<Map<String, dynamic>>> listarEquipos() async {
    final respuesta = await http
        .get(Uri.parse('$baseUrl/api/v1/equipos'))
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudieron consultar los equipos.');
    }

    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final lista = datos['equipos'] as List<dynamic>;

    return lista
        .map((equipo) => Map<String, dynamic>.from(equipo as Map))
        .where(
          (equipo) =>
              equipo['estado']?.toString().toUpperCase() == 'DISPONIBLE',
        )
                .toList();
  }

  // Buscar un equipo por su código QR.
  static Future<Map<String, dynamic>?> buscarEquipoPorCodigo(
    String codigo,
  ) async {
    final respuesta = await http
        .get(Uri.parse('$baseUrl/api/v1/equipos'))
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudieron consultar los equipos.');
    }

    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final lista = datos['equipos'] as List<dynamic>;

    for (final elemento in lista) {
      final equipo = Map<String, dynamic>.from(elemento as Map);

      if (equipo['codigo']?.toString().trim().toUpperCase() ==
          codigo.trim().toUpperCase()) {
        return equipo;
      }
    }

    return null;
  }

  // Crear una solicitud de préstamo.
  // Crear una solicitud de préstamo.
  static Future<Map<String, dynamic>> crearSolicitud({
    required int usuarioId,
    required int equipoId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String motivo,
  }) async {
    try {
      final respuesta = await http
          .post(
            Uri.parse('$baseUrl/api/v1/solicitudes'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'usuarioId': usuarioId,
              'equipoId': equipoId,
              'fechaInicio': fechaInicio.toIso8601String(),
              'fechaFin': fechaFin.toIso8601String(),
              'motivo': motivo.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final datos = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 201) {
        return {
          'exito': true,
          'mensaje': datos['mensaje'] ?? 'Solicitud creada correctamente',
          'solicitud': datos['solicitud'],
        };
      }

      return {
        'exito': false,
        'mensaje': datos['error'] ?? 'No se pudo crear la solicitud',
      };
    } catch (_) {
      return {
        'exito': false,
        'mensaje': 'No se pudo conectar con el servidor.',
      };
    }
  }

  
  // Consultar las solicitudes de un estudiante.
  static Future<List<Map<String, dynamic>>> listarSolicitudes(
    int usuarioId,
  ) async {
    final respuesta = await http
        .get(
          Uri.parse(
            '$baseUrl/api/v1/usuarios/$usuarioId/solicitudes',
          ),
        )
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudieron consultar las solicitudes.');
    }

    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final lista = datos['solicitudes'] as List<dynamic>;

    return lista
        .map((solicitud) => Map<String, dynamic>.from(solicitud as Map))
        .toList();

  }

    // Consultar el historial de préstamos de un estudiante.
  static Future<List<Map<String, dynamic>>> listarPrestamos(
    int usuarioId,
  ) async {
    final respuesta = await http
        .get(
          Uri.parse(
            '$baseUrl/api/v1/usuarios/$usuarioId/prestamos',
          ),
        )
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo consultar el historial de préstamos.');
    }

    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final lista = datos['prestamos'] as List<dynamic>;

    return lista
        .map((prestamo) => Map<String, dynamic>.from(prestamo as Map))
        .toList();
  }

}
