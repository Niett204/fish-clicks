-- Script SQL para crear tabla users e insertar datos de prueba
-- Ejecuta esto en PostgreSQL

-- Crear la tabla
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(255),
    password VARCHAR(255) NOT NULL
);

-- Insertar datos de prueba
INSERT INTO users (email, username, password) VALUES
('juan@example.com', 'juan123', 'password123'),
('maria@example.com', 'maria456', 'micontraseña'),
('carlos@example.com', 'carlos789', 'carlos2024'),
('admin@example.com', 'admin', 'admin123')
ON CONFLICT (email) DO NOTHING;

-- Ver los usuarios creados
SELECT * FROM users;

