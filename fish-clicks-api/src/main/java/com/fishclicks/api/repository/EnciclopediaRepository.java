package com.fishclicks.api.repository;

import com.fishclicks.api.entity.Pez;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface EnciclopediaRepository extends JpaRepository<Pez, Long> {

    @Query("""
        SELECT p
        FROM Pez p
        JOIN p.habitat h
        WHERE p.id IN :ids
          AND (:habitat IS NULL OR h.nombre = :habitat)
          AND (:rareza IS NULL OR p.rareza = :rareza)
    """)
    List<Pez> buscarPeces(
            @Param("ids") List<Long> ids,
            @Param("habitat") String habitat,
            @Param("rareza") String rareza
    );
}