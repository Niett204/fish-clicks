package com.fishclicks.api.service;

import com.fishclicks.api.dto.LoginResponse;
import com.fishclicks.api.entity.Password;
import com.fishclicks.api.entity.User;
import com.fishclicks.api.repository.PasswordRepository;
import com.fishclicks.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;


import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private PasswordRepository passwordRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired(required = false)
    private JavaMailSender mailSender;

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

        // Validar contraseña
        if (!passwordEncoder.matches(password, activePassword.getPasswordHash())) {
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
        newPassword.setPasswordHash(passwordEncoder.encode(password));
        newPassword.setIsActive(true);
        newPassword.setCreatedAt(now);
        passwordRepository.save(newPassword);

        sendWelcomeEmail(email, nickname);

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

    private void sendWelcomeEmail(String toEmail, String nickname) {
        if (mailSender == null) return;

        try {
            SimpleMailMessage mensaje = new SimpleMailMessage();
            // Usa aquí el email que aparece como "Sender" en tu cuenta de Brevo
            mensaje.setFrom("fish.clicks.oficial@gmail.com");
            mensaje.setTo(toEmail);
            mensaje.setSubject("¡Bienvenido a Fish&Clicks!");
            mensaje.setText("¡Bienvenido/a a Fish&Clicks, " + nickname + "!\n\n" +
                    "Estamos muy emocionados de tenerte a bordo. Te damos la bienvenida a este pequeño océano virtual donde tu misión principal es gestionar tu pecera, recolectar doblones y descubrir todos los secretos marinos que hemos preparado para ti.\n\n" +
                    "Actualmente, Fish&Clicks se encuentra en una fase activa de desarrollo. Tu opinión es nuestra herramienta más valiosa.\n\n" +
                    "Si te encuentras con algún bug, error o tienes una idea para mejorar, por favor, háznoslo saber en este cuestionario:\n\n" +
                    "https://docs.google.com/forms/d/e/1FAIpQLSeqxJEQUSS3DzaGipzq1D3xsrB7McNHNjgw3gKbA3TYBTj0NQ/viewform?usp=header\n\n" +
                    "¡Gracias por ayudarnos a hacer de Fish&Clicks un juego mejor! Nos vemos dentro del acuario.");

            mailSender.send(mensaje);
        } catch (Exception e) {
            System.err.println("Error enviando el correo: " + e.getMessage());
        }
    }


    @Async
    public void enviarAvisoMasivo(String asunto, String cuerpo) {
        List<String> emails = userRepository.findAllEmails();

        for (String email : emails) {
            try {
                SimpleMailMessage mensaje = new SimpleMailMessage();
                mensaje.setFrom("fish.clicks.oficial@gmail.com");
                mensaje.setTo(email);
                mensaje.setSubject(asunto);
                mensaje.setText(cuerpo);
                mailSender.send(mensaje);
            } catch (Exception e) {
                System.err.println("Error enviando a " + email + ": " + e.getMessage());
            }
        }
    }
}