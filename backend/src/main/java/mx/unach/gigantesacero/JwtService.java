package mx.unach.gigantesacero;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;

import javax.crypto.SecretKey;
import java.time.Instant;
import java.util.Date;
import java.util.Map;

public class JwtService {

    private static SecretKey obtenerClave() {
        String secreto = System.getenv("JWT_SECRET");

        if (secreto == null || secreto.isBlank()) {
            throw new IllegalStateException(
                "La variable de entorno JWT_SECRET no esta configurada"
            );
        }

        byte[] clave = Decoders.BASE64.decode(secreto);

        if (clave.length < 32) {
            throw new IllegalStateException(
                "JWT_SECRET debe contener al menos 32 bytes"
            );
        }

        return Keys.hmacShaKeyFor(clave);
    }

    public static String generarToken(Map<String, Object> usuario) {
        Instant ahora = Instant.now();

        return Jwts.builder()
            .subject(String.valueOf(usuario.get("id")))
            .claim("rolId", usuario.get("rolId"))
            .issuedAt(Date.from(ahora))
            .expiration(Date.from(ahora.plusSeconds(3600)))
            .signWith(obtenerClave())
            .compact();
    }

    public static Claims validarToken(String token) {
        return Jwts.parser()
            .verifyWith(obtenerClave())
            .build()
            .parseSignedClaims(token)
            .getPayload();
    }
}
