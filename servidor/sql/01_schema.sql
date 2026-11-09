-- Ajustes a la base memory_honduras para conectar la app Flutter
ALTER TABLE usuarios MODIFY correo VARCHAR(100) NULL;
ALTER TABLE usuarios ADD UNIQUE KEY uq_nombre_usuario (nombre_usuario);
ALTER TABLE simbolos
  ADD COLUMN clave VARCHAR(40) NULL UNIQUE AFTER id_simbolo,
  ADD COLUMN datos_curiosos JSON NULL;
UPDATE niveles SET num_parejas = 13 WHERE id_nivel = 3;
