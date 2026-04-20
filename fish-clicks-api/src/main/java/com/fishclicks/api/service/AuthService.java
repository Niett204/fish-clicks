package com.fishclicks.api.service;

import com.fishclicks.api.dto.LoginResponse;
import com.fishclicks.api.entity.Password;
import com.fishclicks.api.entity.User;
import com.fishclicks.api.repository.PasswordRepository;
import com.fishclicks.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private PasswordRepository passwordRepository;

    public LoginResponse login(String identifier, String password){

        String normalizedIdentifier = identifier == null ? "" : identifier.trim();
        if (normalizedIdentifier.isEmpty() || password == null || password.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Identificador y password son obligatorios");
        }

        // Permite iniciar sesión con nickname o email.
        User user = userRepository.findByNicknameIgnoreCaseOrEmailIgnoreCase(normalizedIdentifier, normalizedIdentifier)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Usuario no encontrado"));

        // Obtener la contraseña activa del usuario
        Password activePassword = user.getActivePassword();
        
        if (activePassword == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Usuario sin contraseña activa");
        }

        // Validar contraseña (TODO: implementar BCrypt en el futuro)
        if (!activePassword.getPasswordHash().equals(password)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Contraseña incorrecta");
        }

        // Generar JWT token
        String token = jwtService.generateToken(user.getUid(), user.getEmail());

        return new LoginResponse(
                token,
                user.getUid(),
                user.getEmail(),
                user.getNickname(),
                user.getFoto(),
                user.getFotoExtension()
        );
    }

    @Transactional
    public LoginResponse register(String email, String nickname, String password) {
        String normalizedEmail = email == null ? "" : email.trim();
        String normalizedNickname = nickname == null ? "" : nickname.trim();

        if (normalizedEmail.isEmpty() || normalizedNickname.isEmpty() || password == null || password.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Email, nickname y password son obligatorios");
        }

        if (userRepository.existsByEmailIgnoreCase(normalizedEmail)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "El email ya esta registrado");
        }

        if (userRepository.existsByNicknameIgnoreCase(normalizedNickname)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "El nickname ya esta registrado");
        }

        LocalDateTime now = LocalDateTime.now();

        User user = new User();
        user.setUid(UUID.randomUUID());
        user.setEmail(normalizedEmail);
        user.setNickname(normalizedNickname);
        user.setFoto("");
        user.setCreatedAt(now);
        user.setUpdatedAt(now);

        User createdUser = userRepository.save(user);

        Password newPassword = new Password();
        newPassword.setUser(createdUser);
        // Temporal: se mantiene el mismo criterio actual de login (texto plano).
        newPassword.setPasswordHash(password);
        newPassword.setIsActive(true);
        newPassword.setCreatedAt(now);
        passwordRepository.save(newPassword);

        String token = jwtService.generateToken(createdUser.getUid(), createdUser.getEmail());
        return new LoginResponse(
                token,
                createdUser.getUid(),
                createdUser.getEmail(),
                createdUser.getNickname(),
                createdUser.getFoto(),
                user.getFotoExtension()
        );
    }
}