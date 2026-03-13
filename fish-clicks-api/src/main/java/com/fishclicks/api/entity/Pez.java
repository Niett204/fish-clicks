package com.fishclicks.api.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "pez")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Pez {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nombre;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    @Column(nullable = false)
    private String rareza;

    @Column(name = "efecto_descripcion")
    private String efectoDescripcion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "habitat_id", nullable = false)
    private Habitat habitat;
}