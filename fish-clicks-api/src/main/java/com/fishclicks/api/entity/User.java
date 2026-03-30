package com.fishclicks.api.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name="cuenta")
@Getter
@Setter
public class User {

    @Id
    @Column(name = "uid")
    private UUID uid;

    @Column(name = "nickname")
    private String nickname;

    @Column(name = "email", columnDefinition = "citext")
    private String email;

    @Column(name = "foto")
    private String foto;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY)
    private List<Password> passwords;

    // Método helper para obtener la contraseña activa
    public Password getActivePassword() {
        if (passwords == null) {
            return null;
        }
        return passwords.stream()
            .filter(p -> p.getIsActive() != null && p.getIsActive())
            .findFirst()
            .orElse(null);
    }
}