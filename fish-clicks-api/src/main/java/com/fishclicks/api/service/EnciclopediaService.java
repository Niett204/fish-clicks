package com.fishclicks.api.service;

import com.fishclicks.api.dto.PezDTO;
import com.fishclicks.api.entity.Pez;
import com.fishclicks.api.repository.EnciclopediaRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class EnciclopediaService {

    private final EnciclopediaRepository enciclopediaRepository;

    public EnciclopediaService(EnciclopediaRepository enciclopediaRepository) {
        this.enciclopediaRepository = enciclopediaRepository;
    }

    public List<PezDTO> obtenerPecesDesbloqueados(
            List<Long> pecesDesbloqueados,
            String habitat,
            String rareza
    ) {
        if (pecesDesbloqueados == null || pecesDesbloqueados.isEmpty()) {
            return List.of();
        }

        List<Pez> peces = enciclopediaRepository.buscarPeces(
                pecesDesbloqueados,
                habitat,
                rareza
        );

        return peces.stream()
                .map(this::toDTO)
                .toList();
    }

    private PezDTO toDTO(Pez pez) {
        return new PezDTO(
                pez.getId(),
                pez.getNombre(),
                pez.getDescripcion(),
                pez.getRareza(),
                pez.getEfectoDescripcion(),
                pez.getHabitat().getNombre()
        );
    }
}