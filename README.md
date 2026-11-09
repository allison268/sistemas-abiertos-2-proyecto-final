# Memory Honduras

Juego de memoria con los símbolos patrios y los departamentos de Honduras. Proyecto final de Programación para Sistemas Abiertos II, Universidad Tecnológica de Honduras (UTH).

La app en Flutter solo muestra la interfaz. Los usuarios, las partidas, los puntajes, el ranking y los datos curiosos viven en un servidor Rocky Linux con una API en Node.js y una base de datos MySQL.

## Qué trae

- Tres niveles de dificultad: 4, 8 y 13 pares. Cada nivel ganado desbloquea el siguiente.
- Dos modos de juego: símbolos patrios y departamentos (cartas con la forma de cada departamento).
- Registro e inicio de sesión con contraseña cifrada y sesión con token.
- Ranking global y estadísticas por jugador, calculadas en el servidor.
- Datos curiosos al encontrar cada pareja, generados por Gemini desde el servidor.
- Tienda con pago simulado por tarjeta o PayPal: premium, insignia catracha, donación y diseño dorado de cartas. Solo se guarda una referencia y los últimos 4 dígitos.
- Animaciones en las cartas, confeti y serpentinas al ganar, efectos de sonido y vibración.
- Configuración: sonido, vibración, icono de perfil, cambio de contraseña y acerca de.
- Dos tipos de acceso. El jugador ve las cartas, la tienda y el ranking. El administrador además ve el panel del servidor con las métricas. El servidor rechaza las métricas a cualquier cuenta que no sea administrador.

## Estructura

```
lib/            App Flutter (pantallas, widgets, servicios y modelos)
assets/sonidos/ Efectos de sonido
servidor/       API Node.js + Express, scripts SQL y panel web
servidor/sql/   Scripts de la base de datos, en orden del 01 al 06
```

## Cómo correr el servidor (Rocky Linux)

Requisitos: Node.js 20, MySQL 8.

```
cd servidor
npm install
cp .env.example .env        # llena los datos de tu base y una clave JWT
sudo mysql -e "CREATE DATABASE IF NOT EXISTS memory_honduras CHARACTER SET utf8mb4;"
for f in sql/*.sql; do sudo mysql --force memory_honduras < "$f"; done
node server.js
```

La API queda en el puerto 3000. El panel del administrador está en `http://IP_DEL_SERVIDOR:3000`.

Para crear la cuenta de administrador, regístrate normal desde la app y luego:

```
sudo mysql memory_honduras -e "UPDATE usuarios SET rol='admin' WHERE nombre_usuario='TU_USUARIO';"
```

## Cómo correr la app

```
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=API_URL=http://IP_DEL_SERVIDOR:3000
```

## Rutas principales de la API

| Ruta | Para qué |
| --- | --- |
| `POST /api/registro`, `POST /api/login` | Crear cuenta e iniciar sesión |
| `GET /api/usuarios/me` | Perfil, rol y progreso |
| `POST /api/usuarios/me/contrasena` | Cambiar contraseña |
| `POST /api/partidas` | Guardar una partida |
| `GET /api/ranking` | Ranking global |
| `GET /api/simbolos`, `GET /api/departamentos` | Catálogos de cartas |
| `GET /api/tienda/productos`, `POST /api/tienda/comprar` | Tienda |
| `GET /api/metricas` | Métricas del servidor, solo administrador |

## Equipo

- Allison Gisele Nuñez Aguilar
- Yarely Hissell Hernández Vigil
- Carlos Roberto Martínez Santamaria

Docente: Ing. Luis Valle.
