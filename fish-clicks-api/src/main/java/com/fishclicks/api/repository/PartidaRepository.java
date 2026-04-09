package com.fishclicks.api.repository;

import com.fishclicks.api.entity.Partida;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PartidaRepository extends JpaRepository<Partida, Long> {
    Optional<Partida> findByUserId(UUID userId);
}