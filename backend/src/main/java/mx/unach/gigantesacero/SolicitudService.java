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

    public static List<Map<String, Object>> listarPorUsuario(
            long usuarioId) throws Exception {

        String sql = """
            SELECT
                s.id,
                s.fecha_solicitud,
                s.fecha_inicio,
                s.fecha_fin,
                s.motivo,
                s.estado,
                s.observaciones,
                e.nombre AS equipo_nombre,
                e.codigo_inventario
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
            throw new IllegalArgumentException(
                "El motivo es obligatorio");
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
                      AND estado = 'DISPONIBLE'
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
                    consulta.setTimestamp(3, Timestamp.valueOf(fechaInicio));
                    consulta.setTimestamp(4, Timestamp.valueOf(fechaFin));
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
