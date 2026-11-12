
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
 static const String baseUrl = 'https://germicide-unknowing-delete.ngrok-free.dev';
  // Comprobar la conexiÃ³n con el backend.
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

  // Iniciar sesiÃ³n.
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
          'mensaje': datos['mensaje'] ?? 'Inicio de sesiÃ³n exitoso',
          'usuario': datos['usuario'],
        };
      }

      return {
        'exito': false,
        'mensaje': datos['error'] ?? 'Correo o contraseÃ±a incorrectos',
      };
    } catch (_) {
      return {
        'exito': false,
        'mensaje': 'No se pudo conectar con el servidor.',
      };
    }
  }

  // Registrar una cuenta nueva de estudiante.
  static Future<Map<String, dynamic>> registrarEstudiante({
    required String nombre,
    required String matricula,
    required String correo,
    required String contrasena,
  }) async {
    try {
      final respuesta = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/registro'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nombre': nombre.trim(),
              'matricula': matricula.trim(),
              'correo': correo.trim(),
              'contrasena': contrasena,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final datos = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 201) {
        return {
          'exito': true,
          'mensaje': datos['mensaje'] ?? 'Cuenta creada correctamente',
        };
      }

      return {
        'exito': false,
        'mensaje': datos['error'] ?? 'No se pudo crear la cuenta',
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
        .toList();
  }

  // Buscar un equipo por su cÃ³digo QR.
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

  // Crear una solicitud de prÃ©stamo.
  // Crear una solicitud de prÃ©stamo.
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

    // Consultar el historial de prÃ©stamos de un estudiante.
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
      throw Exception('No se pudo consultar el historial de prÃ©stamos.');
    }

    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final lista = datos['prestamos'] as List<dynamic>;

    return lista
        .map((prestamo) => Map<String, dynamic>.from(prestamo as Map))
        .toList();
  }


  // Consultar todas las solicitudes como administrador.
  static Future<List<Map<String, dynamic>>> listarSolicitudesAdmin(
    int administradorId,
  ) async {
    final respuesta = await http.get(
      Uri.parse(
        '$baseUrl/api/v1/admin/$administradorId/solicitudes',
      ),
    ).timeout(const Duration(seconds: 10));

    final datos = jsonDecode(respuesta.body);

    if (respuesta.statusCode != 200) {
      throw Exception(datos['error'] ?? 'No se pudieron consultar las solicitudes');
    }

    return (datos['solicitudes'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // Aprobar una solicitud.
  static Future<String> aprobarSolicitud(
    int administradorId,
    int solicitudId,
  ) async {
    return _resolverSolicitud(
      administradorId,
      solicitudId,
      'aprobar',
    );
  }

  // Rechazar una solicitud.
  static Future<String> rechazarSolicitud(
    int administradorId,
    int solicitudId,
  ) async {
    return _resolverSolicitud(
      administradorId,
      solicitudId,
      'rechazar',
    );
  }

  static Future<String> _resolverSolicitud(
    int administradorId,
    int solicitudId,
    String accion,
  ) async {
    final respuesta = await http.post(
      Uri.parse(
        '$baseUrl/api/v1/admin/$administradorId/solicitudes/$solicitudId/$accion',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'observaciones': ''}),
    ).timeout(const Duration(seconds: 10));

    final datos = jsonDecode(respuesta.body);

    if (respuesta.statusCode != 200) {
      throw Exception(datos['error'] ?? 'No se pudo procesar la solicitud');
    }

    return datos['mensaje'] ?? 'OperaciÃ³n realizada correctamente';
  }



  // Funciones administrativas
  static Future<List<Map<String, dynamic>>> listarEquiposAdmin(int adminId) async {
    final r = await http.get(Uri.parse('$baseUrl/api/v1/admin/$adminId/equipos'))
        .timeout(const Duration(seconds: 10));
    final d = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(d['error'] ?? 'No se pudieron cargar los equipos');
    return (d['equipos'] as List).map((e) => Map<String,dynamic>.from(e as Map)).toList();
  }

  static Future<String> guardarEquipo(int adminId, Map<String,dynamic> equipo, {int? equipoId}) async {
    final uri = Uri.parse('$baseUrl/api/v1/admin/$adminId/equipos${equipoId == null ? '' : '/$equipoId'}');
    final r = equipoId == null
        ? await http.post(uri, headers: {'Content-Type':'application/json'}, body: jsonEncode(equipo))
        : await http.put(uri, headers: {'Content-Type':'application/json'}, body: jsonEncode(equipo));
    final d = jsonDecode(r.body);
    if (r.statusCode != 200 && r.statusCode != 201) throw Exception(d['error'] ?? 'No se pudo guardar el equipo');
    return d['mensaje'] ?? 'Equipo guardado';
  }

  static Future<String> eliminarEquipo(int adminId, int equipoId) async {
    final r = await http.delete(Uri.parse('$baseUrl/api/v1/admin/$adminId/equipos/$equipoId'))
        .timeout(const Duration(seconds: 10));
    final d = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(d['error'] ?? 'No se pudo dar de baja');
    return d['mensaje'] ?? 'Equipo dado de baja';
  }

  static Future<List<Map<String,dynamic>>> listarPrestamosAdmin(int adminId) async {
    final r = await http.get(Uri.parse('$baseUrl/api/v1/admin/$adminId/prestamos'))
        .timeout(const Duration(seconds: 10));
    final d = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(d['error'] ?? 'No se pudieron cargar los prÃ©stamos');
    return (d['prestamos'] as List).map((e) => Map<String,dynamic>.from(e as Map)).toList();
  }

  static Future<String> devolverPrestamo(int adminId, int prestamoId, {String observaciones = ''}) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/v1/admin/$adminId/prestamos/$prestamoId/devolver'),
      headers: {'Content-Type':'application/json'},
      body: jsonEncode({'observaciones': observaciones}),
    ).timeout(const Duration(seconds: 10));
    final d = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(d['error'] ?? 'No se pudo registrar la devoluciÃ³n');
    return d['mensaje'] ?? 'DevoluciÃ³n registrada';
  }

  static Future<List<Map<String,dynamic>>> listarHistorialEstadosAdmin(int adminId) async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/v1/admin/$adminId/historial-estados'),
    ).timeout(const Duration(seconds: 10));

    final d = jsonDecode(r.body);
    if (r.statusCode != 200) {
      throw Exception(d['error'] ?? 'No se pudo cargar el historial de estados');
    }

    return (d['historial'] as List)
        .map((e) => Map<String,dynamic>.from(e as Map))
        .toList();
  }
  static Future<List<Map<String,dynamic>>> listarQrAdmin(int adminId) async {
    final r = await http.get(Uri.parse('$baseUrl/api/v1/admin/$adminId/qr'))
        .timeout(const Duration(seconds: 10));
    final d = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(d['error'] ?? 'No se pudieron cargar los QR');
    return (d['equipos'] as List).map((e) => Map<String,dynamic>.from(e as Map)).toList();
  }

  static Future<String> reactivarEquipo(int adminId, int equipoId) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/v1/admin/$adminId/equipos/$equipoId/reactivar'),
    ).timeout(const Duration(seconds: 10));
    final d = jsonDecode(r.body);
    if (r.statusCode != 200) {
      throw Exception(d['error'] ?? 'No se pudo reactivar el equipo');
    }
    return d['mensaje'] ?? 'Equipo reactivado';
  }

  static Future<String> devolverPrestamoUsuario(
    int usuarioId,
    int prestamoId, {
    String observaciones = '',
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/v1/usuarios/$usuarioId/prestamos/$prestamoId/devolver'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'observaciones': observaciones}),
    ).timeout(const Duration(seconds: 10));
    final d = jsonDecode(r.body);
    if (r.statusCode != 200) {
      throw Exception(d['error'] ?? 'No se pudo devolver el equipo');
    }
    return d['mensaje'] ?? 'DevoluciÃ³n registrada';
  }
}
