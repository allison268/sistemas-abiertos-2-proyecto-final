-- Agrega PayPal como método de pago y el diseño de cartas doradas
ALTER TABLE compras MODIFY metodo ENUM('tarjeta','billetera','paypal') NOT NULL;

INSERT INTO productos (clave, nombre, descripcion, precio, icono, repetible) VALUES
  ('cartas_doradas', 'Cartas Doradas', 'Diseño premium para tus cartas: reverso dorado, marco brillante y efectos especiales.', 79.00, 'style', 0)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), descripcion = VALUES(descripcion),
  precio = VALUES(precio), icono = VALUES(icono), repetible = VALUES(repetible);
