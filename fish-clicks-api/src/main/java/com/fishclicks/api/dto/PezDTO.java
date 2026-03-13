package com.fishclicks.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PezDTO {

    private Long id;
    private String nombre;
    private String descripcion;
    private String rareza;
    private String efectoDescripcion;
    private String habitat;
}