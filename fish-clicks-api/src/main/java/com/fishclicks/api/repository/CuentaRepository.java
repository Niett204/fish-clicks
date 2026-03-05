package com.fishclicks.api.repository;

import com.fishclicks.api.entity.Cuenta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CuentaRepository extends JpaRepository<Cuenta, UUID> {

    Optional<Cuenta> findByEmail(String email);

}