package com.fishclicks.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.UUID;

@Entity
@Table(name = "cuenta")
@Data
public class Cuenta {

    @Id
    private UUID uid;

    @Column(name = "email", nullable = false, unique = true, columnDefinition = "citext")
    @JdbcTypeCode(SqlTypes.VARCHAR)
    private String email;

    private String nickname;

    private String foto;
}