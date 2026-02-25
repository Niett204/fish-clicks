-- =========================
-- TABLA DE USUARIOS
-- =========================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- TABLA DE PARTIDA (ESTADO JSON)
-- =========================
CREATE TABLE players (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    -- Para ranking rápido (muy importante en un clicker)
    total_clicks BIGINT DEFAULT 0,
    
    -- Estado completo del juego en JSON
    game_state JSONB DEFAULT '{}'::jsonb,
    
    last_save TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice para que el leaderboard sea rápido
CREATE INDEX idx_leaderboard 
ON players (total_clicks DESC);
