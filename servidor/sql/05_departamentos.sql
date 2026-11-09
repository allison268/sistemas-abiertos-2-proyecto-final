-- Modo de juego Departamentos
ALTER TABLE partidas
  ADD COLUMN modo ENUM('simbolos','departamentos') NOT NULL DEFAULT 'simbolos';

CREATE TABLE IF NOT EXISTS departamentos (
  id_departamento INT AUTO_INCREMENT PRIMARY KEY,
  clave           VARCHAR(40) NOT NULL UNIQUE,
  nombre          VARCHAR(60) NOT NULL,
  cabecera        VARCHAR(60) NOT NULL,
  datos_curiosos  JSON NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO departamentos (clave, nombre, cabecera, datos_curiosos) VALUES
  ('atlantida', 'Atlántida', 'La Ceiba', '["Su cabecera, La Ceiba, es famosa por su Carnaval Internacional que se celebra cada mes de mayo.", "Tiene costa en el mar Caribe y en su territorio está el Parque Nacional Pico Bonito.", "Desde La Ceiba salen los barcos hacia las Islas de la Bahía, en especial a Roatán y Utila."]'),
  ('choluteca', 'Choluteca', 'Choluteca', '["Está en el sur de Honduras y tiene costa en el océano Pacífico, en el golfo de Fonseca.", "Su cabecera lleva el mismo nombre y está a orillas del río Choluteca.", "En esta zona se cultivan melón y sandía, y se cría camarón para exportar."]'),
  ('colon', 'Colón', 'Trujillo', '["Cristóbal Colón llegó a esta costa en 1502, en su cuarto viaje, y de él toma su nombre el departamento.", "Trujillo, su cabecera, fue una de las primeras ciudades fundadas en Honduras.", "Aquí viven comunidades garífunas que mantienen su música, su idioma y su comida."]'),
  ('comayagua', 'Comayagua', 'Comayagua', '["Fue la capital de Honduras hasta 1880, cuando la capital pasó a Tegucigalpa.", "Su catedral tiene un reloj de origen árabe, considerado uno de los más antiguos de América.", "Es muy conocida por sus alfombras de aserrín de Semana Santa."]'),
  ('copan', 'Copán', 'Santa Rosa de Copán', '["Aquí están las ruinas mayas de Copán, declaradas Patrimonio Mundial por la UNESCO en 1980.", "Santa Rosa de Copán es famosa por sus puros y su tradición del tabaco.", "Limita con Guatemala, en el occidente del país."]'),
  ('cortes', 'Cortés', 'San Pedro Sula', '["San Pedro Sula, su cabecera, es considerada la capital industrial de Honduras.", "Puerto Cortés es el principal puerto del país.", "Aquí está la Fortaleza de San Fernando de Omoa, una construcción colonial española."]'),
  ('el_paraiso', 'El Paraíso', 'Yuscarán', '["Yuscarán, su cabecera, es un pueblo colonial que nació de la minería.", "Danlí, en este departamento, celebra cada año el Festival del Maíz.", "Limita con Nicaragua, en el oriente del país."]'),
  ('francisco_morazan', 'Francisco Morazán', 'Tegucigalpa', '["Tegucigalpa es la capital de Honduras desde 1880.", "Lleva el nombre del prócer Francisco Morazán, que nació en Tegucigalpa.", "Aquí está el Parque Nacional La Tigra, un bosque nublado cerca de la capital."]'),
  ('gracias_a_dios', 'Gracias a Dios', 'Puerto Lempira', '["Es el departamento de La Mosquitia, una de las zonas más selváticas de Centroamérica.", "Aquí está la Reserva de la Biosfera del Río Plátano, Patrimonio Mundial de la UNESCO.", "En esta región vive el pueblo miskito, entre otros pueblos."]'),
  ('intibuca', 'Intibucá', 'La Esperanza', '["La Esperanza, su cabecera, es una de las ciudades más frías del país.", "Es una zona con fuerte presencia del pueblo lenca.", "Su clima fresco permite cultivar papa y hortalizas."]'),
  ('islas_de_la_bahia', 'Islas de la Bahía', 'Roatán', '["Está formado por las islas de Roatán, Utila y Guanaja, entre otras.", "Cerca de sus costas está el Sistema Arrecifal Mesoamericano, una de las barreras de coral más grandes del mundo.", "Es muy visitado para bucear, y en las islas se habla español e inglés."]'),
  ('la_paz', 'La Paz', 'La Paz', '["Marcala, en este departamento, produce un café con denominación de origen.", "Es un departamento de montañas y clima fresco.", "Su café se cultiva en las montañas, a buena altura sobre el nivel del mar."]'),
  ('lempira', 'Lempira', 'Gracias', '["Lleva el nombre del cacique Lempira, héroe nacional de Honduras.", "La ciudad de Gracias fue sede de la Real Audiencia de los Confines en 1544.", "Aquí está el Parque Nacional Montaña de Celaque, donde se encuentra el Cerro Las Minas, el punto más alto de Honduras."]'),
  ('ocotepeque', 'Ocotepeque', 'Nueva Ocotepeque', '["Limita con Guatemala y El Salvador, en el occidente del país.", "Cerca está la Reserva Trifinio, donde se juntan las fronteras de tres países.", "Tiene clima fresco y es zona de producción de café."]'),
  ('olancho', 'Olancho', 'Juticalpa', '["Es el departamento más grande de Honduras.", "Es famoso por su ganadería, sus bosques y su producción de madera.", "Aquí está el Parque Nacional Sierra de Agalta."]'),
  ('santa_barbara', 'Santa Bárbara', 'Santa Bárbara', '["Parte del Lago de Yojoa está en este departamento.", "Es conocido por sus artesanías hechas con junco.", "En sus montañas se cultiva buena parte del café del occidente del país."]'),
  ('valle', 'Valle', 'Nacaome', '["Tiene costa en el golfo de Fonseca, en el océano Pacífico.", "En el golfo está la Isla del Tigre, con el puerto de Amapala.", "San Lorenzo es uno de sus puertos sobre el Pacífico."]'),
  ('yoro', 'Yoro', 'Yoro', '["Aquí ocurre el fenómeno de la lluvia de peces, que se celebra con una feria.", "Es uno de los departamentos más extensos del norte del país.", "Es un departamento de valles y montañas en el norte de Honduras."]')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), cabecera = VALUES(cabecera),
  datos_curiosos = VALUES(datos_curiosos);
