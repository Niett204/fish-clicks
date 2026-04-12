package com.fishclicks.api.config;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handleResponseStatusException(ResponseStatusException ex) {
        Map<String, Object> body = new HashMap<>();
        // El "reason" es el mensaje que pones en el Service (ej: "Contraseña incorrecta")
        body.put("message", ex.getReason());
        body.put("status", ex.getStatusCode().value());

        return new ResponseEntity<>(body, ex.getStatusCode());
    }
}