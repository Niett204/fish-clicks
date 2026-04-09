package com.fishclicks.api.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "partida")
public class Partida {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "cuenta_uid", nullable = false, unique = true)
    private UUID userId;

    @JdbcTypeCode(SqlTypes.JSON) // Indica a Hibernate que la columna es jsonb en la DB
    @Column(name = "state") // Eliminamos columnDefinition="TEXT" para evitar conflictos
    private String state;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(nullable = false)
    private Instant last_modified;

    @PrePersist
    public void onCreate() {
        createdAt = Instant.now();
        last_modified = Instant.now();
    }

    @PreUpdate
    public void onUpdate() {
        last_modified = Instant.now();
    }
}