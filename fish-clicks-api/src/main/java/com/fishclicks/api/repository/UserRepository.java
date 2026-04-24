package com.fishclicks.api.repository;

import com.fishclicks.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByNicknameIgnoreCaseOrEmailIgnoreCase(String nickname, String email);

    boolean existsByEmailIgnoreCase(String email);

    boolean existsByNicknameIgnoreCase(String nickname);

    // --- NUEVAS CONSULTAS PARA RANKING ---
    // Devuelve los 100 mejores por clics
    List<User> findTop100ByOrderByTotalClicksDesc();

    // Devuelve los 100 mejores por monedas
    List<User> findTop100ByOrderByCoinsDesc();

}