package com.fishclicks.api.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LoginRequest {

    private String nickname;  // Campo principal para login
    private String email;     // Mantenido por compatibilidad
    private String password;

}