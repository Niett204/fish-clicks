package com.fishclicks.api.controller;

import com.fishclicks.api.entity.User;
import com.fishclicks.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;
import java.util.Map;

@RestController
@RequestMapping("/ranking")
public class RankingController {

    @Autowired
    private UserRepository userRepository;

    @GetMapping
    public List<?> getRanking(@RequestParam String type) {
        List<User> users;

        if ("clicks".equalsIgnoreCase(type)) {
            users = userRepository.findTop100ByOrderByTotalClicksDesc();
        } else {
            users = userRepository.findTop100ByOrderByCoinsDesc();
        }

        return users.stream().map(user -> {
            // Usamos un Map genérico para evitar errores de inferencia de tipos
            java.util.Map<String, Object> dto = new java.util.HashMap<>();
            dto.put("nickname", user.getNickname());
            dto.put("score", "clicks".equalsIgnoreCase(type) ? user.getTotalClicks() : user.getCoins());
            dto.put("foto", user.getFoto() != null ? user.getFoto() : "");
            dto.put("foto_extension", user.getFotoExtension() != null ? user.getFotoExtension() : "png");
            return dto;
        }).collect(Collectors.toList());
    }
}