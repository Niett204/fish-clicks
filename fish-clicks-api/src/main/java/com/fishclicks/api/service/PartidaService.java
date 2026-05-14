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
        // 1. Guardar el JSON completo en la tabla 'partida'
        Partida partida = partidaRepository.findByUserId(userId).orElse(new Partida());
        partida.setUserId(userId);
        partida.setState(stateJson);
        partidaRepository.save(partida);

        // 2. Extraer el TOTAL para la tabla 'User' (Ranking)
        try {
            User user = userRepository.findById(userId).orElse(null);
            if (user != null) {
                // CAMBIO CLAVE:
                // Extraemos "total_coins_earned" del JSON y lo guardamos en la columna "coins"
                user.setCoins(extraerDouble(stateJson, "total_coins_earned"));

                user.setTotalClicks(extraerInt(stateJson, "total_clicks"));
                userRepository.save(user);
            }
        } catch (Exception e) {
            System.out.println("Error al actualizar ranking: " + e.getMessage());
        }
    }

    private double extraerDouble(String json, String llave) {
        try {
            // Añadimos la comilla de cierre y el espacio opcional para ser precisos
            String busqueda = "\"" + llave + "\":";
            int inicio = json.indexOf(busqueda);
            if (inicio == -1) return 0.0;

            inicio += busqueda.length();

            // Buscamos donde termina el número (coma o fin de objeto)
            int fin = json.indexOf(",", inicio);
            int finObjeto = json.indexOf("}", inicio);

            if (fin == -1 || (finObjeto != -1 && finObjeto < fin)) fin = finObjeto;

            return Double.parseDouble(json.substring(inicio, fin).trim());
        } catch (Exception e) {
            System.out.println("Error extrayendo double [" + llave + "]: " + e.getMessage());
            return 0.0;
        }
    }

    private int extraerInt(String json, String llave) {
        try {
            String busqueda = "\"" + llave + "\":";
            int inicio = json.indexOf(busqueda);
            if (inicio == -1) return 0;

            inicio += busqueda.length();

            int fin = json.indexOf(",", inicio);
            int finObjeto = json.indexOf("}", inicio);

            if (fin == -1 || (finObjeto != -1 && finObjeto < fin)) fin = finObjeto;

            return Integer.parseInt(json.substring(inicio, fin).trim());
        } catch (Exception e) { return 0; }
    }

    public String cargar(UUID userId) {
        return partidaRepository.findByUserId(userId)
                .map(Partida::getState)
                .orElse(null);
    }
}