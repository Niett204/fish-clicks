package com.fishclicks.api.controller;

import com.fishclicks.api.service.AuthService; // O tu servicio de email
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin")
public class AdminController {

    @Autowired
    private AuthService authService; // Asegúrate de tener el método aquí

    // Para ejecutarlo, llamarías a: POST /admin/enviar-actualizacion
    @PostMapping("/enviar-actualizacion")
    public String enviarAviso(@RequestParam String asunto, @RequestParam String cuerpo) {
        authService.enviarAvisoMasivo(asunto, cuerpo);
        return "Proceso de envío iniciado correctamente.";
    }
}