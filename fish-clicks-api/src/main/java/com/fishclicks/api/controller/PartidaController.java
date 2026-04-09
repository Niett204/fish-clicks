package com.fishclicks.api.controller;

import com.fishclicks.api.service.PartidaService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/partida")
public class PartidaController {

    @Autowired
    private PartidaService partidaService;

    @PostMapping("/guardar")
    public ResponseEntity<?> guardar(
            HttpServletRequest request,
            @RequestBody String body) { // Recibimos el JSON crudo como String

        String userId = (String) request.getAttribute("userId");

        if (body == null || body.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "El cuerpo no puede estar vacío"));
        }

        try {
            // Guardamos el body completo que ya viene en formato JSON desde Godot
            partidaService.guardar(UUID.fromString(userId), body);
            return ResponseEntity.ok(Map.of("message", "Partida guardada correctamente"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/cargar")
    public ResponseEntity<?> cargar(HttpServletRequest request) {
        String userId = (String) request.getAttribute("userId");
        String partidaJson = partidaService.cargar(UUID.fromString(userId));

        if (partidaJson == null) {
            return ResponseEntity.notFound().build();
        }

        // Devolvemos el string directamente en el mapa
        return ResponseEntity.ok(Map.of("state", partidaJson));
    }
}