package com.fishclicks.api.service;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Date;
import java.util.UUID;

@Service
public class JwtService {

    @Value("${jwt.secret:my-super-secret-key-for-fish-clicks-application-please-change-in-production}")
    private String jwtSecret;

    @Value("${jwt.expiration:86400000}")
    private long jwtExpiration;

    private SecretKey getSigningKey() {
        byte[] secretBytes = jwtSecret.getBytes(StandardCharsets.UTF_8);

        // JJWT exige minimo 256 bits para HMAC; si el secreto es corto, derivamos una clave estable.
        if (secretBytes.length < 32) {
            try {
                secretBytes = MessageDigest.getInstance("SHA-512").digest(secretBytes);
            } catch (NoSuchAlgorithmException e) {
                throw new IllegalStateException("No se pudo inicializar SHA-512 para JWT", e);
            }
        }

        return Keys.hmacShaKeyFor(secretBytes);
    }

    public String generateToken(UUID userId, String email) {
        SecretKey key = getSigningKey();
        
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpiration);

        return Jwts.builder()
                .subject(userId.toString())
                .claim("email", email)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }

    public UUID getUserIdFromToken(String token) {
        SecretKey key = getSigningKey();

        return UUID.fromString(
                Jwts.parser()
                        .verifyWith(key)
                        .build()
                        .parseSignedClaims(token)
                        .getPayload()
                        .getSubject()
        );
    }

    public String getEmailFromToken(String token) {
        SecretKey key = getSigningKey();
        
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .get("email", String.class);
    }

    public boolean validateToken(String token) {
        try {
            SecretKey key = getSigningKey();
            Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}

