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

        // Mantenemos la lógica de tipos, pero cambiamos el criterio de búsqueda para el else
        if ("clicks".equalsIgnoreCase(type)) {
            users = userRepository.findTop100ByOrderByTotalClicksDesc();
        } else {
            // Aquí es donde cambiamos a monedas totales (ajusta el método en tu Repository)
            users = userRepository.findTop100ByOrderByCoinsDesc();
        }

        return users.stream().map(user -> {
            java.util.Map<String, Object> dto = new java.util.HashMap<>();
            dto.put("nickname", user.getNickname());

            // El "score" ahora devolverá el total histórico, no el saldo actual (coins)
            dto.put("score", "clicks".equalsIgnoreCase(type) ? user.getTotalClicks() : user.getCoins());

            dto.put("foto", user.getFoto() != null ? user.getFoto() : "");
            dto.put("foto_extension", user.getFotoExtension() != null ? user.getFotoExtension() : "png");
            return dto;
        }).collect(Collectors.toList());
    }
}