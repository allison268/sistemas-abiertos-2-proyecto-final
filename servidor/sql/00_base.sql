-- Tablas base de Memory Honduras.
-- Se corre ANTES que los scripts 01 a 06, porque esos scripts modifican estas tablas.
-- Las columnas salen de lo que usa server.js. Las columnas que agregan los otros
-- scripts (clave, datos_curiosos, modo, rol) NO van aquí para no duplicarlas.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS usuarios (
  id_usuario      INT AUTO_INCREMENT PRIMARY KEY,
  nombre_usuario  VARCHAR(50)  NOT NULL,
  correo          VARCHAR(100) NOT NULL,
  contrasena_hash VARCHAR(255) NOT NULL,
  fecha_registro  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_correo (correo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS niveles (
  id_nivel          INT PRIMARY KEY,
  nombre            VARCHAR(40) NOT NULL,
  dificultad        VARCHAR(20) NOT NULL,
  num_parejas       INT         NOT NULL,
  tiempo_limite_seg INT         NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO niveles (id_nivel, nombre, dificultad, num_parejas, tiempo_limite_seg) VALUES
  (1, 'Nivel 1', 'Fácil',      4,  60),
  (2, 'Nivel 2', 'Intermedio', 8,  60),
  (3, 'Nivel 3', 'Difícil',    13, 60)
ON DUPLICATE KEY UPDATE id_nivel = id_nivel;

CREATE TABLE IF NOT EXISTS simbolos (
  id_simbolo  INT AUTO_INCREMENT PRIMARY KEY,
  nombre      VARCHAR(60)  NOT NULL,
  descripcion VARCHAR(255) NOT NULL,
  imagen      VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS partidas (
  id_partida          INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario          INT NOT NULL,
  id_nivel            INT NOT NULL,
  resultado           ENUM('ganada','perdida') NOT NULL,
  puntaje             INT NOT NULL DEFAULT 0,
  errores             INT NOT NULL DEFAULT 0,
  intentos            INT NOT NULL DEFAULT 0,
  parejas_encontradas INT NOT NULL DEFAULT 0,
  duracion_seg        INT NOT NULL DEFAULT 0,
  fecha_partida       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_partidas_usuario (id_usuario),
  KEY idx_partidas_nivel (id_nivel),
  CONSTRAINT fk_partidas_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario),
  CONSTRAINT fk_partidas_nivel   FOREIGN KEY (id_nivel)   REFERENCES niveles (id_nivel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Vista que usa la ruta /api/usuarios/me/estadisticas
CREATE OR REPLACE VIEW vw_estadisticas_usuario AS
SELECT u.id_usuario,
       COUNT(p.id_partida)                         AS partidas_jugadas,
       COALESCE(SUM(p.resultado = 'ganada'), 0)    AS ganadas,
       COALESCE(SUM(p.resultado = 'perdida'), 0)   AS perdidas,
       COALESCE(ROUND(100 * SUM(p.resultado = 'ganada') / NULLIF(COUNT(p.id_partida), 0), 1), 0)
                                                   AS promedio_victorias
  FROM usuarios u
  LEFT JOIN partidas p ON p.id_usuario = u.id_usuario
 GROUP BY u.id_usuario;
