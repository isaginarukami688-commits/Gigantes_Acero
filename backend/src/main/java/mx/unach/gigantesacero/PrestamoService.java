
package mx.unach.gigantesacero;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class PrestamoService {

    public static List<Map<String, Object>> listarPorUsuario(
            long usuarioId) throws Exception {

        String sql = """
            SELECT
                p.id,
                p.solicitud_id,
                p.fecha_prestamo,
                p.fecha_devolucion_prevista,
                p.fecha_devolucion_real,
                p.estado,
                p.observaciones,
                e.nombre AS equipo_nombre,
                e.codigo_inventario
            FROM prestamos p
            INNER JOIN equipos e ON e.id = p.equipo_id
            WHERE p.usuario_id = ?
            ORDER BY p.fecha_prestamo DESC NULLS LAST, p.id DESC
        """;

        List<Map<String, Object>> prestamos = new ArrayList<>();

        try (Connection conexion = Database.getConnection();
             PreparedStatement consulta =
                 conexion.prepareStatement(sql)) {

            consulta.setLong(1, usuarioId);

            try (ResultSet resultado = consulta.executeQuery()) {
                while (resultado.next()) {
                    Map<String, Object> prestamo =
                        new LinkedHashMap<>();

                    prestamo.put("id", resultado.getLong("id"));

                    long solicitudId =
                        resultado.getLong("solicitud_id");
                    prestamo.put(
                        "solicitudId",
                        resultado.wasNull() ? null : solicitudId
                    );

                    prestamo.put(
                        "fechaPrestamo",
                        resultado.getTimestamp("fecha_prestamo") == null
                            ? null
                            : resultado.getTimestamp(
                                "fecha_prestamo").toString()
                    );

                    prestamo.put(
                        "fechaDevolucionPrevista",
                        resultado.getTimestamp(
                            "fecha_devolucion_prevista") == null
                            ? null
                            : resultado.getTimestamp(
                                "fecha_devolucion_prevista").toString()
                    );

                    prestamo.put(
                        "fechaDevolucionReal",
                        resultado.getTimestamp(
                            "fecha_devolucion_real") == null
                            ? null
                            : resultado.getTimestamp(
                                "fecha_devolucion_real").toString()
                    );

                    prestamo.put("estado", resultado.getString("estado"));
                    prestamo.put(
                        "observaciones",
                        resultado.getString("observaciones")
                    );
                    prestamo.put(
                        "equipoNombre",
                        resultado.getString("equipo_nombre")
                    );
                    prestamo.put(
                        "codigoInventario",
                        resultado.getString("codigo_inventario")
                    );

                    prestamos.add(prestamo);
                }
            }
        }

        return prestamos;
    }
    public static void devolverPrestamo(long usuarioId, long prestamoId,
            String observaciones) throws Exception {
        try (Connection c = Database.getConnection()) {
            c.setAutoCommit(false);
            try {
                long equipoId;
                try (PreparedStatement ps = c.prepareStatement("""
                    SELECT equipo_id, estado,
                           (fecha_prestamo <= CURRENT_TIMESTAMP) AS iniciado
                    FROM prestamos
                    WHERE id = ? AND usuario_id = ?
                    FOR UPDATE
                """)) {
                    ps.setLong(1, prestamoId);
                    ps.setLong(2, usuarioId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new IllegalArgumentException(
                            "No existe ese préstamo para este usuario");
                        if (!"ACTIVO".equals(rs.getString("estado")))
                            throw new IllegalArgumentException("El préstamo ya fue devuelto");
                        if (!rs.getBoolean("iniciado"))
                            throw new IllegalArgumentException(
                                "El préstamo aún no ha comenzado; no se puede registrar la devolución");
                        equipoId = rs.getLong("equipo_id");
                    }
                }

                String estadoAnterior;
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT estado FROM equipos WHERE id = ? FOR UPDATE")) {
                    ps.setLong(1, equipoId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new IllegalArgumentException("El equipo no existe");
                        estadoAnterior = rs.getString("estado");
                    }
                }

                try (PreparedStatement ps = c.prepareStatement("""
                    UPDATE prestamos
                    SET estado = 'DEVUELTO',
                        fecha_devolucion_real = CURRENT_TIMESTAMP,
                        observaciones = COALESCE(?, observaciones)
                    WHERE id = ? AND usuario_id = ? AND estado = 'ACTIVO'
                """)) {
                    ps.setString(1, observaciones);
                    ps.setLong(2, prestamoId);
                    ps.setLong(3, usuarioId);
                    if (ps.executeUpdate() != 1)
                        throw new IllegalArgumentException("No se pudo registrar la devolución");
                }

                try (PreparedStatement ps = c.prepareStatement("""
                    UPDATE equipos
                    SET estado = CASE
                        WHEN activo = FALSE OR estado = 'BAJA' THEN 'BAJA'
                        WHEN estado = 'MANTENIMIENTO' THEN 'MANTENIMIENTO'
                        ELSE 'DISPONIBLE'
                    END
                    WHERE id = ?
                """)) {
                    ps.setLong(1, equipoId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = c.prepareStatement("""
                    INSERT INTO historial_estados
                        (equipo_id, usuario_id, estado_anterior, estado_nuevo, observaciones)
                    SELECT p.equipo_id, ?, ?, e.estado, ?
                    FROM prestamos p
                    JOIN equipos e ON e.id = p.equipo_id
                    WHERE p.id = ?
                """)) {
                    ps.setLong(1, usuarioId);
                    ps.setString(2, estadoAnterior);
                    ps.setString(3, observaciones);
                    ps.setLong(4, prestamoId);
                    ps.executeUpdate();
                }

                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw e;
            } finally {
                c.setAutoCommit(true);
            }
        }
    }
}
