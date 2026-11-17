package mx.unach.gigantesacero;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Map;

import org.mindrot.jbcrypt.BCrypt;

public class AuthService {

    public static Map<String, Object> iniciarSesion(
            String correo,
            String contrasena) throws Exception {

        String sql = """
            SELECT id, nombre, correo_institucional,
                   password_hash, rol_id, laboratorio_id, activo
            FROM usuarios
            WHERE correo_institucional = ?
        """;

        try (Connection conexion = Database.getConnection();
             PreparedStatement consulta = conexion.prepareStatement(sql)) {

            consulta.setString(1, correo);

            try (ResultSet resultado = consulta.executeQuery()) {

                if (!resultado.next()) {
                    return null;
                }

                String hash = resultado.getString("password_hash");
                boolean activo = resultado.getBoolean("activo");

                if (!activo || hash == null
                        || !BCrypt.checkpw(contrasena, hash)) {
                    return null;
                }

                Map<String, Object> usuario = new HashMap<>();
                usuario.put("id", resultado.getLong("id"));
                usuario.put("nombre", resultado.getString("nombre"));
                usuario.put(
                    "correo",
                    resultado.getString("correo_institucional")
                );
                usuario.put("rolId", resultado.getLong("rol_id"));

                long laboratorioId = resultado.getLong("laboratorio_id");
                if (!resultado.wasNull()) {
                    usuario.put("laboratorioId", laboratorioId);
                }

                return usuario;
            }
        }
    }
}