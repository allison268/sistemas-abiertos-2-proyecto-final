-- Pagos reales con PayPal (o tarjeta procesada por PayPal).
-- Cada fila es una orden de PayPal. Cuando PayPal confirma el cobro,
-- el servidor agrega la compra a la tabla "compras" como siempre.
CREATE TABLE IF NOT EXISTS pagos_paypal (
  id_orden     VARCHAR(40)  NOT NULL PRIMARY KEY,
  id_usuario   INT          NOT NULL,
  id_producto  INT          NOT NULL,
  metodo       ENUM('tarjeta','paypal') NOT NULL,
  monto_hnl    DECIMAL(8,2) NOT NULL,
  monto_usd    DECIMAL(8,2) NOT NULL,
  estado       ENUM('creada','procesando','completada','cancelada','fallida') NOT NULL DEFAULT 'creada',
  referencia   VARCHAR(24)  NULL,
  detalle      VARCHAR(255) NULL,
  fecha_creada TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_pagos_usuario (id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
