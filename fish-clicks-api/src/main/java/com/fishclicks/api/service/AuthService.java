package com.fishclicks.api.service;

import com.fishclicks.api.dto.LoginResponse;
import com.fishclicks.api.entity.User;
import com.fishclicks.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtService jwtService;

    public LoginResponse login(String email, String password){

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if(!user.getPassword().equals(password)){
            throw new RuntimeException("Invalid password");
        }

        String token = jwtService.generateToken(user.getId(), user.getEmail());

        return new LoginResponse(token, user.getId());
    }
}