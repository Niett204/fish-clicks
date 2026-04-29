package com.fishclicks.api.service;

import com.fishclicks.api.entity.Partida;
import com.fishclicks.api.entity.User;
import com.fishclicks.api.repository.PartidaRepository;
import com.fishclicks.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class PartidaService {

    @Autowired
    private PartidaRepository partidaRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public void guardar(UUID userId, String stateJson) {
        // 1. Guardar la partida original
        Partida partida = partidaRepository.findByUserId(userId).orElse(new Partida());
        partida.setUserId(userId);
        partida.setState(stateJson);
        partidaRepository.save(partida);

        // 2. Extraer valores "a mano" buscando en el texto
        try {
            User user = userRepository.findById(userId).orElse(null);
            if (user != null) {
                // Buscamos "coins": valor
                user.setCoins(extraerDouble(stateJson, "coins"));
                // Buscamos "total_clicks": valor
                user.setTotalClicks(extraerInt(stateJson, "total_clicks"));

                userRepository.save(user);
            }
        } catch (Exception e) {
            System.out.println("Error manual al extraer stats: " + e.getMessage());
        }
    }

    // Funciones auxiliares para buscar en el String sin usar Mappers
    private double extraerDouble(String json, String llave) {
        try {
            String busqueda = "\"" + llave + "\":";
            int inicio = json.indexOf(busqueda) + busqueda.length();
            int fin = json.indexOf(",", inicio);
            if (fin == -1) fin = json.indexOf("}", inicio);
            return Double.parseDouble(json.substring(inicio, fin).trim());
        } catch (Exception e) { return 0.0; }
    }

    private int extraerInt(String json, String llave) {
        try {
            String busqueda = "\"" + llave + "\":";
            int inicio = json.indexOf(busqueda) + busqueda.length();
            int fin = json.indexOf(",", inicio);
            if (fin == -1) fin = json.indexOf("}", inicio);
            return Integer.parseInt(json.substring(inicio, fin).trim());
        } catch (Exception e) { return 0; }
    }

    public String cargar(UUID userId) {
        return partidaRepository.findByUserId(userId)
                .map(Partida::getState)
                .orElse(null);
    }
}