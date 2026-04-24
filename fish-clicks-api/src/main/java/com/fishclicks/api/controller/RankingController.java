package com.fishclicks.api.controller;

import com.fishclicks.api.dto.RankingDTO;
import com.fishclicks.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/ranking")
public class RankingController {

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/clicks")
    public List<RankingDTO> getTopClicks() {
        return userRepository.findTop100ByOrderByTotalClicksDesc().stream()
                .map(u -> new RankingDTO(u.getNickname(), (double) u.getTotalClicks()))
                .collect(Collectors.toList());
    }

    @GetMapping("/money")
    public List<RankingDTO> getTopMoney() {
        return userRepository.findTop100ByOrderByCoinsDesc().stream()
                .map(u -> new RankingDTO(u.getNickname(), u.getCoins()))
                .collect(Collectors.toList());
    }
}