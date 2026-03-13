package com.fishclicks.api.controller;

import com.fishclicks.api.dto.PecesRequest;
import com.fishclicks.api.dto.PezDTO;
import com.fishclicks.api.facade.EnciclopediaFacade;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/enciclopedia")
public class EnciclopediaController {

    private final EnciclopediaFacade enciclopediaFacade;

    public EnciclopediaController(EnciclopediaFacade enciclopediaFacade) {
        this.enciclopediaFacade = enciclopediaFacade;
    }

    @PostMapping("/peces")
    public List<PezDTO> obtenerPeces(
            @RequestParam(required = false) String habitat,
            @RequestParam(required = false) String rareza,
            @RequestBody PecesRequest request
    ) {
        return enciclopediaFacade.obtenerPecesDesbloqueados(
                request.getPeces(),
                habitat,
                rareza
        );
    }
}