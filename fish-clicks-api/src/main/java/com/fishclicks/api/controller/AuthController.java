package com.fishclicks.api.controller;

import com.fishclicks.api.dto.LoginRequest;
import com.fishclicks.api.dto.LoginResponse;
import com.fishclicks.api.service.AuthService;
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
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request){

        LoginResponse loginResponse = authService.login(
                request.getEmail(),
                request.getPassword()
        );

        return ResponseEntity.ok(loginResponse);
    }
}