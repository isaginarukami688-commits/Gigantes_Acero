package mx.unach.gigantesacero;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class Database {

    private static final Properties properties = new Properties();

    static {
        try (InputStream input = Database.class
                .getClassLoader()
                .getResourceAsStream("application.properties")) {

            if (input == null) {
                throw new IllegalStateException(
                    "No se encontró application.properties"
                );
            }

            properties.load(input);

        } catch (Exception e) {
            throw new RuntimeException(
                "Error al cargar la configuración de la base de datos", e
            );
        }
    }

    public static Connection getConnection() throws SQLException {
        String url = System.getenv().getOrDefault("DB_URL", properties.getProperty("db.url"));
        String username = System.getenv().getOrDefault("DB_USERNAME", properties.getProperty("db.username"));
        String password = System.getenv("DB_PASSWORD");

        if (password == null || password.isBlank()) {
            throw new IllegalStateException(
                "La variable de entorno DB_PASSWORD no está configurada"
            );
        }

        return DriverManager.getConnection(url, username, password);
    }

    public static boolean testConnection() {
        try (Connection connection = getConnection()) {
            return connection.isValid(5);
        } catch (Exception e) {
            System.err.println(
                "Error de conexión con PostgreSQL: " + e.getMessage()
            );
            return false;
        }
    }
}