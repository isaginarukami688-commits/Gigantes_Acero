package mx.unach.gigantesacero;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Locale;

import org.mindrot.jbcrypt.BCrypt;

public class RegistroService {

    public static long registrarEstudiante(
            String nombre,
            String matricula,
            String correo,
            String contrasena) throws Exception {

        if (nombre == null || nombre.isBlank()
                || matricula == null || matricula.isBlank()
                || correo == null || correo.isBlank()
                || contrasena == null || contrasena.isBlank()) {
            throw new IllegalArgumentException("Todos los campos son obligatorios.");
        }

        nombre = nombre.trim();
        matricula = matricula.trim().toUpperCase(Locale.ROOT);
        correo = correo.trim().toLowerCase(Locale.ROOT);

        if (nombre.length() > 100) {
            throw new IllegalArgumentException("El nombre es demasiado largo.");
        }

        if (!matricula.matches("[A-Z0-9-]{4,30}")) {
            throw new IllegalArgumentException("La matrícula debe tener entre 4 y 30 caracteres alfanuméricos.");
        }

        if (correo.length() > 150
                || !correo.matches("^[a-z0-9._%+-]+@unach\\.mx$")) {
            throw new IllegalArgumentException("Ingresa un correo institucional válido terminado en @unach.mx.");
        }

        if (contrasena.length() < 8 || contrasena.length() > 72) {
            throw new IllegalArgumentException("La contraseña debe tener entre 8 y 72 caracteres.");
        }

        String hash = BCrypt.hashpw(contrasena, BCrypt.gensalt(12));

        String sql = """
            INSERT INTO usuarios
                (nombre, matricula, correo_institucional,
                 password_hash, rol_id, laboratorio_id, activo)
            VALUES (?, ?, ?, ?, 3, NULL, TRUE)
            RETURNING id
        """;

        try (Connection conexion = Database.getConnection();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setString(1, nombre);
            ps.setString(2, matricula);
            ps.setString(3, correo);
            ps.setString(4, hash);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id");
                }
            }

            throw new SQLException("No se obtuvo el identificador del usuario.");

        } catch (SQLException e) {
            if ("23505".equals(e.getSQLState())) {
                throw new IllegalArgumentException(
                    "La matrícula o el correo institucional ya están registrados."
                );
            }
            throw e;
        }
    }
}