package com.fishclicks.api.controller;

import com.fishclicks.api.dto.LoginRequest;
import com.fishclicks.api.dto.LoginResponse;
import com.fishclicks.api.dto.RegisterRequest;
import com.fishclicks.api.repository.UserRepository;
import com.fishclicks.api.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

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

    @Transactional
    @PostMapping("/update-photo")
    public ResponseEntity<?> updatePhoto(HttpServletRequest request, @RequestBody Map<String, String> body) {
        // El userId lo sacamos del atributo que setea el JwtFilter
        String userIdStr = (String) request.getAttribute("userId");
        String base64Foto = body.get("foto");

        if (userIdStr == null || base64Foto == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Datos incompletos"));
        }

        return userRepository.findById(UUID.fromString(userIdStr))
                .map(user -> {
                    user.setFoto(base64Foto);
                    user.setUpdatedAt(LocalDateTime.now());
                    userRepository.save(user);
                    return ResponseEntity.ok(Map.of("message", "Foto actualizada con éxito"));
                })
                .orElse(ResponseEntity.status(404).body(Map.of("error", "Usuario no encontrado")));
    }
}