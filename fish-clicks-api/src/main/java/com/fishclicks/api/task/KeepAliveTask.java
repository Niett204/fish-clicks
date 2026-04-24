package com.fishclicks.api.task;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class KeepAliveTask {

    private final RestTemplate restTemplate = new RestTemplate();

    // Se ejecuta cada 12 minutos (720,000 milisegundos)
    // El límite de Render suele estar en 15 min.
    @Scheduled(fixedRate = 720000)
    public void selfPing() {
        try {
            // RECUERDA: Cambia esta URL por la URL real de tu backend en Render
            String url = "https://fish-clicks.onrender.com";

            String response = restTemplate.getForObject(url, String.class);
            System.out.println(">>> Auto-ping realizado con éxito para mantener el servidor despierto.");
        } catch (Exception e) {
            // Es normal que falle si el endpoint requiere un Token y no lo envías,
            // pero para Render, la "petición" ya cuenta como actividad.
            System.err.println(">>> El auto-ping falló, pero la petición llegó al servidor.");
        }
    }
}