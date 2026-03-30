package com.fishclicks.api.controller;

import com.fishclicks.api.dto.LoginRequest;
import com.fishclicks.api.dto.LoginResponse;
import com.fishclicks.api.dto.RegisterRequest;
import com.fishclicks.api.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request){

        // Acepta nickname o email; prioriza el que venga no vacio.
        String identifier = request.getNickname();
        if (identifier == null || identifier.isBlank()) {
            identifier = request.getEmail();
        }
        
        LoginResponse loginResponse = authService.login(
                identifier,
                request.getPassword()
        );

        return ResponseEntity.ok(loginResponse);
    }

    @PostMapping("/register")
    public ResponseEntity<LoginResponse> register(@Valid @RequestBody RegisterRequest request) {
        LoginResponse registerResponse = authService.register(
                request.getEmail(),
                request.getNickname(),
                request.getPassword()
        );

        return ResponseEntity.ok(registerResponse);
    }
}