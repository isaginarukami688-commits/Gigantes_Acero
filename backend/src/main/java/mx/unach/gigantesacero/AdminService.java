package mx.unach.gigantesacero;

import java.sql.*;
import java.util.*;

public class AdminService {
    private static void verificarAdmin(Connection c, long adminId) throws Exception {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT 1 FROM usuarios WHERE id=? AND rol_id=1 AND activo=TRUE")) {
            ps.setLong(1, adminId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new IllegalArgumentException("El usuario no es un administrador activo");
            }
        }
    }

    public static List<Map<String,Object>> listarEquipos(long adminId) throws Exception {
        String sql = """
            SELECT e.id, e.codigo_inventario, e.nombre, e.descripcion,
                   e.laboratorio_id, l.nombre AS laboratorio, e.estado, e.activo,
                   q.codigo_qr
            FROM equipos e
            LEFT JOIN laboratorios l ON l.id=e.laboratorio_id
            LEFT JOIN equipo_qr_index q ON q.equipo_id=e.id
            ORDER BY e.id DESC
        """;
        List<Map<String,Object>> lista = new ArrayList<>();
        try (Connection c=Database.getConnection()) {
            verificarAdmin(c,adminId);
            try (PreparedStatement ps=c.prepareStatement(sql); ResultSet rs=ps.executeQuery()) {
                while(rs.next()) {
                    Map<String,Object> m=new LinkedHashMap<>();
                    m.put("id",rs.getLong("id"));
                    m.put("codigo",rs.getString("codigo_inventario"));
                    m.put("nombre",rs.getString("nombre"));
                    m.put("descripcion",rs.getString("descripcion"));
                    m.put("laboratorioId",rs.getLong("laboratorio_id"));
                    m.put("laboratorio",rs.getString("laboratorio"));
                    m.put("estado",rs.getString("estado"));
                    m.put("activo",rs.getBoolean("activo"));
                    m.put("codigoQr",rs.getString("codigo_qr"));
                    lista.add(m);
                }
            }
        }
        return lista;
    }

    public static Map<String,Object> crearEquipo(long adminId, String codigo,
            String nombre, String descripcion, long laboratorioId) throws Exception {
        validarEquipo(codigo,nombre,laboratorioId);
        String sql = """
            INSERT INTO equipos(codigo_inventario,nombre,descripcion,laboratorio_id)
            VALUES(?,?,?,?) RETURNING id
        """;
        try(Connection c=Database.getConnection()) {
            verificarAdmin(c,adminId);
            c.setAutoCommit(false);
            try {
                long id;
                try(PreparedStatement ps=c.prepareStatement(sql)) {
                    ps.setString(1,codigo.trim());
                    ps.setString(2,nombre.trim());
                    ps.setString(3,descripcion);
                    ps.setLong(4,laboratorioId);
                    try(ResultSet rs=ps.executeQuery()) { rs.next(); id=rs.getLong(1); }
                }
                guardarQR(c,id,codigo.trim());
                try (PreparedStatement h = c.prepareStatement("""
                    INSERT INTO historial_estados
                        (equipo_id, usuario_id, estado_anterior, estado_nuevo, observaciones)
                    VALUES (?, ?, NULL, 'DISPONIBLE', 'Equipo creado')
                """)) {
                    h.setLong(1, id);
                    h.setLong(2, adminId);
                    h.executeUpdate();
                }
                c.commit();
                Map<String,Object> m=new LinkedHashMap<>();
                m.put("id",id); m.put("codigo",codigo.trim()); m.put("nombre",nombre.trim());
                m.put("descripcion",descripcion); m.put("laboratorioId",laboratorioId);
                m.put("estado","DISPONIBLE"); m.put("activo",true); m.put("codigoQr",codigo.trim());
                return m;
            } catch(Exception e) { c.rollback(); throw e; }
            finally { c.setAutoCommit(true); }
        }
    }

    public static void actualizarEquipo(long adminId, long equipoId, String codigo,
            String nombre, String descripcion, long laboratorioId, String estado) throws Exception {

        validarEquipo(codigo, nombre, laboratorioId);

        if (estado == null || !Set.of("DISPONIBLE", "SOLICITADO", "PRESTADO",
                "MANTENIMIENTO", "BAJA").contains(estado)) {
            throw new IllegalArgumentException("El estado del equipo no es válido");
        }

        try (Connection c = Database.getConnection()) {
            verificarAdmin(c, adminId);
            c.setAutoCommit(false);

            try {
                String estadoAnterior;

                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT estado FROM equipos WHERE id = ? FOR UPDATE")) {
                    ps.setLong(1, equipoId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("El equipo no existe");
                        }
                        estadoAnterior = rs.getString("estado");
                    }
                }

                String sql = """
                    UPDATE equipos
                    SET codigo_inventario = ?, nombre = ?, descripcion = ?,
                        laboratorio_id = ?, estado = ?
                    WHERE id = ?
                """;

                try (PreparedStatement ps = c.prepareStatement(sql)) {
                    ps.setString(1, codigo.trim());
                    ps.setString(2, nombre.trim());
                    ps.setString(3, descripcion);
                    ps.setLong(4, laboratorioId);
                    ps.setString(5, estado);
                    ps.setLong(6, equipoId);
                    ps.executeUpdate();
                }

                guardarQR(c, equipoId, codigo.trim());

                if (!estado.equals(estadoAnterior)) {
                    try (PreparedStatement h = c.prepareStatement("""
                        INSERT INTO historial_estados
                            (equipo_id, usuario_id, estado_anterior, estado_nuevo, observaciones)
                        VALUES (?, ?, ?, ?, 'Estado actualizado por administrador')
                    """)) {
                        h.setLong(1, equipoId);
                        h.setLong(2, adminId);
                        h.setString(3, estadoAnterior);
                        h.setString(4, estado);
                        h.executeUpdate();
                    }
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


    public static void desactivarEquipo(long adminId, long equipoId) throws Exception {
        try (Connection c = Database.getConnection()) {
            verificarAdmin(c, adminId);
            c.setAutoCommit(false);

            try {
                String estadoAnterior;

                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT estado FROM equipos WHERE id = ? FOR UPDATE")) {
                    ps.setLong(1, equipoId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalArgumentException("El equipo no existe");
                        }
                        estadoAnterior = rs.getString("estado");
                    }
                }

                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT 1 FROM prestamos WHERE equipo_id = ? AND estado = 'ACTIVO'")) {
                    ps.setLong(1, equipoId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            throw new IllegalArgumentException(
                                "No se puede dar de baja: el equipo tiene un préstamo activo");
                        }
                    }
                }

                try (PreparedStatement ps = c.prepareStatement(
                        "UPDATE equipos SET activo = FALSE, estado = 'BAJA' WHERE id = ?")) {
                    ps.setLong(1, equipoId);
                    ps.executeUpdate();
                }

                if (!"BAJA".equals(estadoAnterior)) {
                    try (PreparedStatement h = c.prepareStatement("""
                        INSERT INTO historial_estados
                            (equipo_id, usuario_id, estado_anterior, estado_nuevo, observaciones)
                        VALUES (?, ?, ?, 'BAJA', 'Equipo dado de baja')
                    """)) {
                        h.setLong(1, equipoId);
                        h.setLong(2, adminId);
                        h.setString(3, estadoAnterior);
                        h.executeUpdate();
                    }
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


    public static void reactivarEquipo(long adminId, long equipoId) throws Exception {
        try (Connection c = Database.getConnection()) {
            verificarAdmin(c, adminId);
            c.setAutoCommit(false);
            try {
                boolean activo;
                String estadoAnterior;

                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT activo, estado FROM equipos WHERE id = ? FOR UPDATE")) {
                    ps.setLong(1, equipoId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new IllegalArgumentException("El equipo no existe");
                        activo = rs.getBoolean("activo");
                        estadoAnterior = rs.getString("estado");
                    }
                }

                if (activo) throw new IllegalArgumentException("El equipo ya está activo");

                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT 1 FROM prestamos WHERE equipo_id = ? AND estado = 'ACTIVO'")) {
                    ps.setLong(1, equipoId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) throw new IllegalArgumentException(
                            "No se puede reactivar: el equipo tiene un préstamo activo");
                    }
                }

                try (PreparedStatement ps = c.prepareStatement(
                        "UPDATE equipos SET activo = TRUE, estado = 'DISPONIBLE' WHERE id = ?")) {
                    ps.setLong(1, equipoId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = c.prepareStatement("""
                    INSERT INTO historial_estados
                        (equipo_id, usuario_id, estado_anterior, estado_nuevo, observaciones)
                    VALUES (?, ?, ?, 'DISPONIBLE', 'Equipo reactivado')
                """)) {
                    ps.setLong(1, equipoId);
                    ps.setLong(2, adminId);
                    ps.setString(3, estadoAnterior);
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
    public static List<Map<String,Object>> listarPrestamos(long adminId) throws Exception {
        String sql="""
            SELECT p.id,p.usuario_id,u.nombre AS usuario_nombre,
                   p.equipo_id,e.nombre AS equipo_nombre,e.codigo_inventario,
                   p.fecha_prestamo,p.fecha_devolucion_prevista,
                   p.fecha_devolucion_real,p.estado,p.observaciones
            FROM prestamos p
            JOIN usuarios u ON u.id=p.usuario_id
            JOIN equipos e ON e.id=p.equipo_id
            ORDER BY p.fecha_prestamo DESC,p.id DESC
        """;
        List<Map<String,Object>> lista=new ArrayList<>();
        try(Connection c=Database.getConnection()) {
            verificarAdmin(c,adminId);
            try(PreparedStatement ps=c.prepareStatement(sql);ResultSet rs=ps.executeQuery()) {
                while(rs.next()) {
                    Map<String,Object> m=new LinkedHashMap<>();
                    m.put("id",rs.getLong("id")); m.put("usuarioId",rs.getLong("usuario_id"));
                    m.put("usuarioNombre",rs.getString("usuario_nombre"));
                    m.put("equipoId",rs.getLong("equipo_id"));
                    m.put("equipoNombre",rs.getString("equipo_nombre"));
                    m.put("codigoInventario",rs.getString("codigo_inventario"));
                    m.put("fechaPrestamo",rs.getTimestamp("fecha_prestamo").toString());
                    m.put("fechaDevolucionPrevista",rs.getTimestamp("fecha_devolucion_prevista").toString());
                    Timestamp real=rs.getTimestamp("fecha_devolucion_real");
                    m.put("fechaDevolucionReal",real==null?null:real.toString());
                    m.put("estado",rs.getString("estado")); m.put("observaciones",rs.getString("observaciones"));
                    lista.add(m);
                }
            }
        }
        return lista;
    }

    public static void devolverPrestamo(long adminId,long prestamoId,String observaciones) throws Exception {
        try(Connection c=Database.getConnection()) {
            verificarAdmin(c,adminId); c.setAutoCommit(false);
            try {
                long equipoId;
                try(PreparedStatement ps=c.prepareStatement(
                    "SELECT equipo_id,estado,(fecha_prestamo <= CURRENT_TIMESTAMP) AS iniciado FROM prestamos WHERE id=? FOR UPDATE")) {
                    ps.setLong(1,prestamoId);
                    try(ResultSet rs=ps.executeQuery()) {
                        if(!rs.next()) throw new IllegalArgumentException("El préstamo no existe");
                        if(!"ACTIVO".equals(rs.getString("estado")))
                            throw new IllegalArgumentException("El préstamo ya fue devuelto");
                        if (!rs.getBoolean("iniciado"))
                            throw new IllegalArgumentException("El préstamo aún no ha comenzado; no se puede registrar la devolución");
                        equipoId=rs.getLong("equipo_id");
                    }
                }
                try(PreparedStatement ps=c.prepareStatement("""
                    UPDATE prestamos SET estado='DEVUELTO',fecha_devolucion_real=CURRENT_TIMESTAMP,
                    recibido_por=?,observaciones=COALESCE(?,observaciones) WHERE id=?
                """)) {
                    ps.setLong(1,adminId); ps.setString(2,observaciones); ps.setLong(3,prestamoId); ps.executeUpdate();
                }
                String anterior;
                try(PreparedStatement ps=c.prepareStatement("SELECT estado FROM equipos WHERE id=? FOR UPDATE")) {
                    ps.setLong(1,equipoId);
                    try(ResultSet rs=ps.executeQuery()) { rs.next(); anterior=rs.getString(1); }
                }
                try(PreparedStatement ps=c.prepareStatement("""
                    UPDATE equipos
                    SET estado = CASE
                        WHEN activo = FALSE OR estado = 'BAJA' THEN 'BAJA'
                        WHEN estado = 'MANTENIMIENTO' THEN 'MANTENIMIENTO'
                        ELSE 'DISPONIBLE'
                    END
                    WHERE id=?
                """)) {
                    ps.setLong(1,equipoId); ps.executeUpdate();
                }
                try(PreparedStatement ps=c.prepareStatement("""
                    INSERT INTO historial_estados(equipo_id,usuario_id,estado_anterior,estado_nuevo,observaciones)
                    SELECT p.equipo_id, p.usuario_id, ?, e.estado, ?
FROM prestamos p
JOIN equipos e ON e.id = p.equipo_id
WHERE p.id = ?
                """)) {
                    ps.setString(1,anterior); ps.setString(2,observaciones); ps.setLong(3,prestamoId); ps.executeUpdate();
                }
                c.commit();
            } catch(Exception e) { c.rollback(); throw e; }
            finally { c.setAutoCommit(true); }
        }
    }

    public static List<Map<String,Object>> listarHistorialEstados(long adminId) throws Exception {
        String sql = """
            SELECT h.id, h.equipo_id, e.codigo_inventario,
                   e.nombre AS equipo_nombre,
                   h.usuario_id, u.nombre AS usuario_nombre,
                   h.estado_anterior, h.estado_nuevo,
                   h.fecha_cambio, h.observaciones
            FROM historial_estados h
            JOIN equipos e ON e.id = h.equipo_id
            LEFT JOIN usuarios u ON u.id = h.usuario_id
            ORDER BY h.fecha_cambio DESC, h.id DESC
        """;

        List<Map<String,Object>> lista = new ArrayList<>();

        try (Connection c = Database.getConnection()) {
            verificarAdmin(c, adminId);

            try (PreparedStatement ps = c.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String,Object> m = new LinkedHashMap<>();
                    m.put("id", rs.getLong("id"));
                    m.put("equipoId", rs.getLong("equipo_id"));
                    m.put("codigoInventario", rs.getString("codigo_inventario"));
                    m.put("equipoNombre", rs.getString("equipo_nombre"));
                    m.put("usuarioId", rs.getObject("usuario_id"));
                    m.put("usuarioNombre", rs.getString("usuario_nombre"));
                    m.put("estadoAnterior", rs.getString("estado_anterior"));
                    m.put("estadoNuevo", rs.getString("estado_nuevo"));
                    m.put("fechaCambio", rs.getTimestamp("fecha_cambio").toString());
                    m.put("observaciones", rs.getString("observaciones"));
                    lista.add(m);
                }
            }
        }

        return lista;
    }
    private static void guardarQR(Connection c,long equipoId,String codigo) throws Exception {
        try(PreparedStatement ps=c.prepareStatement("""
            INSERT INTO equipo_qr_index(equipo_id,codigo_qr) VALUES(?,?)
            ON CONFLICT(equipo_id) DO UPDATE SET codigo_qr=EXCLUDED.codigo_qr
        """)) {
            ps.setLong(1,equipoId); ps.setString(2,codigo); ps.executeUpdate();
        }
    }
    private static void validarEquipo(String codigo,String nombre,long laboratorioId) {
        if(codigo==null||codigo.isBlank()||nombre==null||nombre.isBlank()||laboratorioId<=0)
            throw new IllegalArgumentException("Código, nombre y laboratorio son obligatorios");
    }
}
