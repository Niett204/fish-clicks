package com.fishclicks.api.facade;

import com.fishclicks.api.dto.PezDTO;
import com.fishclicks.api.service.EnciclopediaService;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class EnciclopediaFacade {

    private final EnciclopediaService enciclopediaService;

    public EnciclopediaFacade(EnciclopediaService enciclopediaService) {
        this.enciclopediaService = enciclopediaService;
    }

    public List<PezDTO> obtenerPecesDesbloqueados(
            List<Long> pecesDesbloqueados,
            String habitat,
            String rareza
    ) {
        return enciclopediaService.obtenerPecesDesbloqueados(
                pecesDesbloqueados,
                habitat,
                rareza
        );
    }
}