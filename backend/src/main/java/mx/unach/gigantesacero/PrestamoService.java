
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
}
