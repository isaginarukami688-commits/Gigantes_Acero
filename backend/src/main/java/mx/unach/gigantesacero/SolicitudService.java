
package mx.unach.gigantesacero;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SolicitudService {

    private static long obtenerEquipoSolicitud(Connection conexion, long solicitudId) throws Exception {
        try (PreparedStatement consulta = conexion.prepareStatement(
                "SELECT equipo_id FROM solicitudes WHERE id = ?")) {
            consulta.setLong(1, solicitudId);
            try (ResultSet resultado = consulta.executeQuery()) {
                if (!resultado.next()) {
                    throw new IllegalArgumentException("La solicitud no existe");
                }
                return resultado.getLong("equipo_id");
            }
        }
    }

    private static void verificarAdministrador(
            Connection conexion, long administradorId) throws Exception {

        String sql = """
            SELECT id FROM usuarios
            WHERE id = ? AND rol_id = 1 AND activo = TRUE
        """;

        try (PreparedStatement consulta = conexion.prepareStatement(sql)) {
            consulta.setLong(1, administradorId);
            try (ResultSet resultado = consulta.executeQuery()) {
                if (!resultado.next()) {
                    throw new IllegalArgumentException(
                        "El usuario no es un administrador activo");
                }
            }
        }
    }

    public static List<Map<String, Object>> listarPorUsuario(
            long usuarioId) throws Exception {

        String sql = """
            SELECT s.id, s.fecha_solicitud, s.fecha_inicio, s.fecha_fin,
                   s.motivo, s.estado, s.observaciones,
                   e.nombre AS equipo_nombre, e.codigo_inventario
            FROM solicitudes s
            INNER JOIN equipos e ON e.id = s.equipo_id
            WHERE s.usuario_id = ?
            ORDER BY s.fecha_solicitud DESC
        """;

        List<Map<String, Object>> solicitudes = new ArrayList<>();

        try (Connection conexion = Database.getConnection();
             PreparedStatement consulta = conexion.prepareStatement(sql)) {

            consulta.setLong(1, usuarioId);

            try (ResultSet resultado = consulta.executeQuery()) {
                while (resultado.next()) {
                    Map<String, Object> solicitud = new HashMap<>();
                    solicitud.put("id", resultado.getLong("id"));
                    solicitud.put("fechaSolicitud",
                        resultado.getTimestamp("fecha_solicitud").toString());
                    solicitud.put("fechaInicio",
                        resultado.getTimestamp("fecha_inicio").toString());
                    solicitud.put("fechaFin",
                        resultado.getTimestamp("fecha_fin").toString());
                    solicitud.put("motivo", resultado.getString("motivo"));
                    solicitud.put("estado", resultado.getString("estado"));
                    solicitud.put("observaciones",
                        resultado.getString("observaciones"));
                    solicitud.put("equipoNombre",
                        resultado.getString("equipo_nombre"));
                    solicitud.put("codigoInventario",
                        resultado.getString("codigo_inventario"));
                    solicitudes.add(solicitud);
                }
            }
        }
        return solicitudes;
    }

    public static List<Map<String, Object>> listarTodas(
            long administradorId) throws Exception {

        String sql = """
            SELECT s.id, s.fecha_solicitud, s.fecha_inicio, s.fecha_fin,
                   s.motivo, s.estado, s.observaciones,
                   s.usuario_id, u.nombre AS usuario_nombre,
                   u.correo_institucional,
                   e.nombre AS equipo_nombre, e.codigo_inventario
            FROM solicitudes s
            INNER JOIN usuarios u ON u.id = s.usuario_id
            INNER JOIN equipos e ON e.id = s.equipo_id
            ORDER BY
                CASE WHEN s.estado = 'PENDIENTE' THEN 0 ELSE 1 END,
                s.fecha_solicitud DESC
        """;

        List<Map<String, Object>> solicitudes = new ArrayList<>();

        try (Connection conexion = Database.getConnection()) {
            verificarAdministrador(conexion, administradorId);

            try (PreparedStatement consulta = conexion.prepareStatement(sql);
                 ResultSet resultado = consulta.executeQuery()) {

                while (resultado.next()) {
                    Map<String, Object> item = new HashMap<>();
                    item.put("id", resultado.getLong("id"));
                    item.put("usuarioId", resultado.getLong("usuario_id"));
                    item.put("usuarioNombre",
                        resultado.getString("usuario_nombre"));
                    item.put("correo",
                        resultado.getString("correo_institucional"));
                    item.put("equipoNombre",
                        resultado.getString("equipo_nombre"));
                    item.put("codigoInventario",
                        resultado.getString("codigo_inventario"));
                    item.put("fechaSolicitud",
                        resultado.getTimestamp("fecha_solicitud").toString());
                    item.put("fechaInicio",
                        resultado.getTimestamp("fecha_inicio").toString());
                    item.put("fechaFin",
                        resultado.getTimestamp("fecha_fin").toString());
                    item.put("motivo", resultado.getString("motivo"));
                    item.put("estado", resultado.getString("estado"));
                    item.put("observaciones",
                        resultado.getString("observaciones"));
                    solicitudes.add(item);
                }
            }
        }
        return solicitudes;
    }

    public static void aprobarSolicitud(
            long solicitudId,
            long administradorId,
            String observaciones) throws Exception {

        try (Connection conexion = Database.getConnection()) {
            conexion.setAutoCommit(false);

            try {
                verificarAdministrador(conexion, administradorId);

                long usuarioId;
                long equipoId;
                LocalDateTime fechaInicio;
                LocalDateTime fechaFin;
                String estado;

                String buscar = """
                    SELECT usuario_id, equipo_id, fecha_inicio,
                           fecha_fin, estado
                    FROM solicitudes
                    WHERE id = ?
                    FOR UPDATE
                """;

                try (PreparedStatement consulta =
                         conexion.prepareStatement(buscar)) {
                    consulta.setLong(1, solicitudId);

                    try (ResultSet resultado = consulta.executeQuery()) {
                        if (!resultado.next()) {
                            throw new IllegalArgumentException(
                                "La solicitud no existe");
                        }

                        usuarioId = resultado.getLong("usuario_id");
                        equipoId = resultado.getLong("equipo_id");
                        fechaInicio = resultado.getTimestamp(
                            "fecha_inicio").toLocalDateTime();
                        fechaFin = resultado.getTimestamp(
                            "fecha_fin").toLocalDateTime();
                        estado = resultado.getString("estado");
                    }
                }

                if (!"PENDIENTE".equals(estado)) {
                    throw new IllegalArgumentException(
                        "La solicitud ya fue revisada");
                }

                String estadoAnterior;
                String equipoSql = """
                    SELECT id, estado FROM equipos
                    WHERE id = ? AND activo = TRUE
                      AND estado IN ('DISPONIBLE', 'SOLICITADO')
                    FOR UPDATE
                """;

                try (PreparedStatement consulta =
                         conexion.prepareStatement(equipoSql)) {
                    consulta.setLong(1, equipoId);
                    try (ResultSet resultado = consulta.executeQuery()) {
                        if (!resultado.next()) {
                            throw new IllegalArgumentException(
                                "El equipo ya no está disponible");
                        }
                                            estadoAnterior = resultado.getString("estado");
}
                }

                String insertarPrestamo = """
                    INSERT INTO prestamos
                        (solicitud_id, usuario_id, equipo_id,
                         fecha_prestamo, fecha_devolucion_prevista,
                         estado, observaciones)
                    VALUES (?, ?, ?, ?, ?, 'ACTIVO', ?)
                """;

                try (PreparedStatement consulta =
                         conexion.prepareStatement(insertarPrestamo)) {
                    consulta.setLong(1, solicitudId);
                    consulta.setLong(2, usuarioId);
                    consulta.setLong(3, equipoId);
                    consulta.setTimestamp(4,
                        Timestamp.valueOf(fechaInicio));
                    consulta.setTimestamp(5,
                        Timestamp.valueOf(fechaFin));
                    consulta.setString(6, observaciones);
                    consulta.executeUpdate();
                }

                String actualizarSolicitud = """
                    UPDATE solicitudes
                    SET estado = 'APROBADA',
                        revisado_por = ?,
                        revisado_en = CURRENT_TIMESTAMP,
                        observaciones = ?
                    WHERE id = ?
                """;

                try (PreparedStatement consulta =
                         conexion.prepareStatement(actualizarSolicitud)) {
                    consulta.setLong(1, administradorId);
                    consulta.setString(2, observaciones);
                    consulta.setLong(3, solicitudId);
                    consulta.executeUpdate();
                }

                try (PreparedStatement consulta =
                         conexion.prepareStatement(
                             "UPDATE equipos SET estado = 'PRESTADO' WHERE id = ?")) {
                    consulta.setLong(1, equipoId);
                    consulta.executeUpdate();
                }

                try (PreparedStatement historial = conexion.prepareStatement("""
                    INSERT INTO historial_estados
                        (equipo_id, usuario_id, estado_anterior, estado_nuevo, observaciones)
                    VALUES (?, ?, ?, 'PRESTADO', ?)
                """)) {
                    historial.setLong(1, equipoId);
                    historial.setLong(2, administradorId);
                    historial.setString(3, estadoAnterior);
                    historial.setString(4, observaciones);
                    historial.executeUpdate();
                }

                conexion.commit();

            } catch (Exception e) {
                conexion.rollback();
                throw e;
            } finally {
                conexion.setAutoCommit(true);
            }
        }
    }

    public static void rechazarSolicitud(
            long solicitudId,
            long administradorId,
            String observaciones) throws Exception {

        try (Connection conexion = Database.getConnection()) {
            conexion.setAutoCommit(false);

            try {
                verificarAdministrador(conexion, administradorId);

                long equipoId;
                long usuarioId;

                String bloquear = """
                    SELECT equipo_id, usuario_id
                    FROM solicitudes
                    WHERE id = ? AND estado = 'PENDIENTE'
                    FOR UPDATE
                """;

                try (PreparedStatement ps = conexion.prepareStatement(bloquear)) {
                    ps.setLong(1, solicitudId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException(
                                "La solicitud no existe o ya fue revisada");
                        }

                        equipoId = rs.getLong("equipo_id");
                        usuarioId = rs.getLong("usuario_id");
                    }
                }

                String rechazar = """
                    UPDATE solicitudes
                    SET estado = 'RECHAZADA',
                        revisado_por = ?,
                        revisado_en = CURRENT_TIMESTAMP,
                        observaciones = ?
                    WHERE id = ? AND estado = 'PENDIENTE'
                """;

                try (PreparedStatement ps = conexion.prepareStatement(rechazar)) {
                    ps.setLong(1, administradorId);
                    ps.setString(2, observaciones);
                    ps.setLong(3, solicitudId);

                    if (ps.executeUpdate() == 0) {
                        throw new IllegalArgumentException(
                            "No fue posible rechazar la solicitud");
                    }
                }

                String liberar = """
                    UPDATE equipos e
                    SET estado = 'DISPONIBLE'
                    WHERE e.id = ?
                      AND e.activo = TRUE
                      AND e.estado = 'SOLICITADO'
                      AND NOT EXISTS (
                          SELECT 1 FROM solicitudes s
                          WHERE s.equipo_id = e.id
                            AND s.estado = 'PENDIENTE'
                      )
                      AND NOT EXISTS (
                          SELECT 1 FROM prestamos p
                          WHERE p.equipo_id = e.id
                            AND p.estado = 'ACTIVO'
                      )
                """;

                try (PreparedStatement ps = conexion.prepareStatement(liberar)) {
                    ps.setLong(1, equipoId);

                    if (ps.executeUpdate() > 0) {
                        String historial = """
                            INSERT INTO historial_estados
                                (equipo_id, usuario_id, estado_anterior,
                                 estado_nuevo, observaciones)
                            VALUES (?, ?, 'SOLICITADO', 'DISPONIBLE', ?)
                        """;

                        try (PreparedStatement registro =
                                 conexion.prepareStatement(historial)) {
                            registro.setLong(1, equipoId);
                            registro.setLong(2, usuarioId);
                            registro.setString(3, observaciones);
                            registro.executeUpdate();
                        }
                    }
                }

                conexion.commit();

            } catch (Exception e) {
                conexion.rollback();
                throw e;
            } finally {
                conexion.setAutoCommit(true);
            }
        }
    }
    public static Map<String, Object> crearSolicitud(
            long usuarioId,
            long equipoId,
            LocalDateTime fechaInicio,
            LocalDateTime fechaFin,
            String motivo) throws Exception {

        if (usuarioId <= 0 || equipoId <= 0) {
            throw new IllegalArgumentException(
                "El usuario y el equipo deben ser válidos");
        }

        if (fechaInicio == null || fechaFin == null
                || !fechaFin.isAfter(fechaInicio)) {
            throw new IllegalArgumentException(
                "La fecha final debe ser posterior a la inicial");
        }

        if (motivo == null || motivo.isBlank()) {
            throw new IllegalArgumentException("El motivo es obligatorio");
        }

        try (Connection conexion = Database.getConnection()) {
            conexion.setAutoCommit(false);

            try {
                String verificarUsuario = """
                    SELECT id FROM usuarios
                    WHERE id = ? AND activo = TRUE
                """;

                try (PreparedStatement consulta =
                         conexion.prepareStatement(verificarUsuario)) {
                    consulta.setLong(1, usuarioId);
                    try (ResultSet resultado = consulta.executeQuery()) {
                        if (!resultado.next()) {
                            throw new IllegalArgumentException(
                                "El usuario no existe o está inactivo");
                        }
                    }
                }

                String verificarEquipo = """
                    SELECT id FROM equipos
                    WHERE id = ? AND activo = TRUE
                      AND estado IN ('DISPONIBLE', 'SOLICITADO')
                    FOR UPDATE
                """;

                try (PreparedStatement consulta =
                         conexion.prepareStatement(verificarEquipo)) {
                    consulta.setLong(1, equipoId);
                    try (ResultSet resultado = consulta.executeQuery()) {
                        if (!resultado.next()) {
                            throw new IllegalArgumentException(
                                "El equipo no está disponible");
                        }
                    }
                }

                try (PreparedStatement actualizarEquipo = conexion.prepareStatement(
                        "UPDATE equipos SET estado = 'SOLICITADO' WHERE id = ? AND estado = 'DISPONIBLE' AND activo = TRUE")) {
                    actualizarEquipo.setLong(1, equipoId);
                    if (actualizarEquipo.executeUpdate() == 0) {
                        throw new IllegalArgumentException("El equipo dejó de estar disponible");
                    }
                }

                String insertar = """
                    INSERT INTO solicitudes
                        (usuario_id, equipo_id, fecha_inicio,
                         fecha_fin, motivo, estado)
                    VALUES (?, ?, ?, ?, ?, 'PENDIENTE')
                    RETURNING id, fecha_solicitud, estado
                """;

                Map<String, Object> nuevaSolicitud = new HashMap<>();

                try (PreparedStatement consulta =
                         conexion.prepareStatement(insertar)) {
                    consulta.setLong(1, usuarioId);
                    consulta.setLong(2, equipoId);
                    consulta.setTimestamp(3,
                        Timestamp.valueOf(fechaInicio));
                    consulta.setTimestamp(4,
                        Timestamp.valueOf(fechaFin));
                    consulta.setString(5, motivo.trim());

                    try (ResultSet resultado = consulta.executeQuery()) {
                        resultado.next();
                        nuevaSolicitud.put("id", resultado.getLong("id"));
                        nuevaSolicitud.put("fechaSolicitud",
                            resultado.getTimestamp("fecha_solicitud").toString());
                        nuevaSolicitud.put("estado",
                            resultado.getString("estado"));
                    }
                }

                conexion.commit();
                return nuevaSolicitud;

            } catch (Exception e) {
                conexion.rollback();
                throw e;
            } finally {
                conexion.setAutoCommit(true);
            }
        }
    }
}

