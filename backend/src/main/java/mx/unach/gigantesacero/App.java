
package mx.unach.gigantesacero;

import io.javalin.Javalin;
import java.util.Map;

public class App {

    public static void main(String[] args) {
        Javalin app = Javalin.create(config -> {
            config.http.defaultContentType = "application/json";
        });

        // Ruta principal
        app.get("/", ctx -> {
            ctx.json(Map.of(
                "aplicacion", "Gigantes_Acero Respaldo",
                "mensaje", "Backend de respaldo funcionando"
            ));
        });

        // Comprobar conexión con la base de datos
        app.get("/api/v1/health", ctx -> {
            boolean conectado = Database.testConnection();

            ctx.status(conectado ? 200 : 503);
            ctx.json(Map.of(
                "estado", conectado ? "disponible" : "sin_conexion",
                "baseDatos", "gigantes_acero_respaldo"
            ));
        });

        // Iniciar sesión
        app.post("/api/v1/auth/login", ctx -> {
            LoginRequest solicitud =
                ctx.bodyAsClass(LoginRequest.class);

            String correo = solicitud.correo();
            String contrasena = solicitud.contrasena();

            if (correo == null || correo.isBlank()
                    || contrasena == null || contrasena.isBlank()) {
                ctx.status(400);
                ctx.json(Map.of(
                    "error", "El correo y la contraseña son obligatorios"
                ));
                return;
            }

            try {
                Map<String, Object> usuario =
                    AuthService.iniciarSesion(
                        correo.trim(),
                        contrasena
                    );

                if (usuario == null) {
                    ctx.status(401);
                    ctx.json(Map.of(
                        "error",
                        "Correo o contraseña incorrectos, o cuenta inactiva"
                    ));
                    return;
                }

                ctx.status(200);
                ctx.json(Map.of(
                    "mensaje", "Inicio de sesión exitoso",
                    "usuario", usuario
                ));

            } catch (Exception e) {
                System.err.println(
                    "Error al iniciar sesión: " + e.getMessage()
                );

                ctx.status(500);
                ctx.json(Map.of(
                    "error",
                    "No se pudo procesar el inicio de sesión"
                ));
            }
        });

        // Crear solicitud de préstamo
        app.post("/api/v1/solicitudes", ctx -> {
            try {
                SolicitudRequest solicitud =
                    ctx.bodyAsClass(SolicitudRequest.class);

                if (solicitud.usuarioId() <= 0
                        || solicitud.equipoId() <= 0
                        || solicitud.motivo() == null
                        || solicitud.motivo().isBlank()
                        || solicitud.fechaInicio() == null
                        || solicitud.fechaFin() == null) {

                    ctx.status(400);
                    ctx.json(Map.of(
                        "error",
                        "Todos los campos son obligatorios y válidos"
                    ));
                    return;
                }

                var nuevaSolicitud =
                    SolicitudService.crearSolicitud(
                        solicitud.usuarioId(),
                        solicitud.equipoId(),
                        java.time.LocalDateTime.parse(
                            solicitud.fechaInicio()
                        ),
                        java.time.LocalDateTime.parse(
                            solicitud.fechaFin()
                        ),
                        solicitud.motivo()
                    );

                ctx.status(201);
                ctx.json(Map.of(
                    "mensaje", "Solicitud creada correctamente",
                    "solicitud", nuevaSolicitud
                ));

            } catch (IllegalArgumentException e) {
                ctx.status(400);
                ctx.json(Map.of("error", e.getMessage()));

            } catch (java.time.format.DateTimeParseException e) {
                ctx.status(400);
                ctx.json(Map.of(
                    "error", "Las fechas deben tener un formato válido"
                ));

            } catch (Exception e) {
                System.err.println(
                    "Error al crear solicitud: " + e.getMessage()
                );

                ctx.status(500);
                ctx.json(Map.of(
                    "error", "No se pudo crear la solicitud"
                ));
            }
        });

        // Consultar solicitudes de un usuario
        app.get("/api/v1/usuarios/{usuarioId}/solicitudes", ctx -> {
            try {
                long usuarioId = Long.parseLong(
                    ctx.pathParam("usuarioId")
                );

                if (usuarioId <= 0) {
                    ctx.status(400);
                    ctx.json(Map.of(
                        "error", "El identificador debe ser positivo"
                    ));
                    return;
                }

                var solicitudes =
                    SolicitudService.listarPorUsuario(usuarioId);

                ctx.status(200);
                ctx.json(Map.of("solicitudes", solicitudes));

            } catch (NumberFormatException e) {
                ctx.status(400);
                ctx.json(Map.of(
                    "error", "Identificador de usuario inválido"
                ));

            } catch (Exception e) {
                System.err.println(
                    "Error al consultar solicitudes: " + e.getMessage()
                );

                ctx.status(500);
                ctx.json(Map.of(
                    "error", "No se pudieron consultar las solicitudes"
                ));
            }
        });

        // NUEVO: consultar historial de préstamos de un usuario
        app.get("/api/v1/usuarios/{usuarioId}/prestamos", ctx -> {
            try {
                long usuarioId = Long.parseLong(
                    ctx.pathParam("usuarioId")
                );

                if (usuarioId <= 0) {
                    ctx.status(400);
                    ctx.json(Map.of(
                        "error", "El identificador debe ser positivo"
                    ));
                    return;
                }

                var prestamos =
                    PrestamoService.listarPorUsuario(usuarioId);

                ctx.status(200);
                ctx.json(Map.of("prestamos", prestamos));

            } catch (NumberFormatException e) {
                ctx.status(400);
                ctx.json(Map.of(
                    "error", "Identificador de usuario inválido"
                ));

            } catch (Exception e) {
                System.err.println(
                    "Error al consultar préstamos: " + e.getMessage()
                );

                ctx.status(500);
                ctx.json(Map.of(
                    "error", "No se pudieron consultar los préstamos"
                ));
            }
        });

        // Consultar catálogo de equipos
        app.get("/api/v1/equipos", ctx -> {
            try (var conexion = Database.getConnection();
                 var consulta = conexion.prepareStatement(
                     "SELECT id, codigo_inventario, nombre, " +
                     "descripcion, laboratorio_id, estado " +
                     "FROM equipos " +
                     "WHERE activo = TRUE " +
                     "ORDER BY nombre"
                 );
                 var resultado = consulta.executeQuery()) {

                var equipos = new java.util.ArrayList<
                    Map<String, Object>
                >();

                while (resultado.next()) {
                    var equipo = new java.util.LinkedHashMap<
                        String, Object
                    >();

                    equipo.put("id", resultado.getLong("id"));
                    equipo.put(
                        "codigo",
                        resultado.getString("codigo_inventario")
                    );
                    equipo.put(
                        "nombre",
                        resultado.getString("nombre")
                    );
                    equipo.put(
                        "descripcion",
                        resultado.getString("descripcion")
                    );
                    equipo.put(
                        "laboratorioId",
                        resultado.getLong("laboratorio_id")
                    );
                    equipo.put(
                        "estado",
                        resultado.getString("estado")
                    );

                    equipos.add(equipo);
                }

                ctx.status(200);
                ctx.json(Map.of("equipos", equipos));

            } catch (Exception e) {
                System.err.println(
                    "Error al consultar equipos: " + e.getMessage()
                );

                ctx.status(500);
                ctx.json(Map.of(
                    "error", "No se pudieron consultar los equipos"
                ));
            }
        });

        // Iniciar servidor
        app.start(7001);

        System.out.println(
            "Backend de respaldo iniciado en http://localhost:7001"
        );
    }

    public record LoginRequest(
        String correo,
        String contrasena
    ) {}

    public record SolicitudRequest(
        long usuarioId,
        long equipoId,
        String fechaInicio,
        String fechaFin,
        String motivo
    ) {}
}
