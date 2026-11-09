-- Roles de usuario: jugador (por defecto) o admin
ALTER TABLE usuarios
  ADD COLUMN rol ENUM('jugador','admin') NOT NULL DEFAULT 'jugador';
