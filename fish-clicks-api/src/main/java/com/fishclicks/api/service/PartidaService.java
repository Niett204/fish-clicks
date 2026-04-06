package com.fishclicks.api.service;

import com.fishclicks.api.entity.Partida;
import com.fishclicks.api.repository.PartidaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class PartidaService {

    @Autowired
    private PartidaRepository partidaRepository;

    public void guardar(UUID userId, String stateJson) {
        // Intentamos buscar una partida existente para este usuario
        Partida partida = partidaRepository.findByUserId(userId)
                .orElse(new Partida());

        partida.setUserId(userId);
        partida.setState(stateJson); // Guardamos el String tal cual

        partidaRepository.save(partida);
    }

    public String cargar(UUID userId) {
        return partidaRepository.findByUserId(userId)
                .map(Partida::getState)
                .orElse(null);
    }
}