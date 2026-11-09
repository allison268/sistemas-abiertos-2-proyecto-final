-- Tienda con pago simulado de Memory Honduras
CREATE TABLE IF NOT EXISTS productos (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  clave       VARCHAR(40)  NOT NULL UNIQUE,
  nombre      VARCHAR(80)  NOT NULL,
  descripcion VARCHAR(255) NOT NULL,
  precio      DECIMAL(8,2) NOT NULL,
  icono       VARCHAR(40)  NOT NULL,
  repetible   TINYINT(1)   NOT NULL DEFAULT 0,
  activo      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS compras (
  id_compra    INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario   INT          NOT NULL,
  id_producto  INT          NOT NULL,
  monto        DECIMAL(8,2) NOT NULL,
  metodo       ENUM('tarjeta','billetera') NOT NULL,
  ultimos4     CHAR(4)      NOT NULL,
  referencia   VARCHAR(24)  NOT NULL UNIQUE,
  estado       ENUM('aprobada','rechazada') NOT NULL DEFAULT 'aprobada',
  fecha_compra TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_compras_usuario (id_usuario),
  KEY idx_compras_producto (id_producto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO productos (clave, nombre, descripcion, precio, icono, repetible) VALUES
  ('premium', 'Memory Premium', 'Insignia dorada junto a tu nombre y apoyo al desarrollo del juego.', 99.00, 'workspace_premium', 0),
  ('insignia_catracho', 'Insignia Catracho', 'Una insignia con los colores de la bandera en tu perfil.', 29.00, 'flag', 0),
  ('donacion', 'Apoyo a la educación', 'Una donación para llevar el juego a más escuelas de Honduras.', 25.00, 'volunteer_activism', 1)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), descripcion = VALUES(descripcion),
  precio = VALUES(precio), icono = VALUES(icono), repetible = VALUES(repetible);
