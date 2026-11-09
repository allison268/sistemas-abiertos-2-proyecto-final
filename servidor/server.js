require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const mysql = require('mysql2/promise');
const os = require('os');
const path = require('path');

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  console.error('Falta JWT_SECRET en el archivo .env');
  process.exit(1);
}

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  charset: 'utf8mb4',
  waitForConnections: true,
  connectionLimit: 10,
});

const app = express();
app.use(cors());
app.use(express.json({ limit: '100kb' }));

const ah = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

function auth(req, res, next) {
  const cabecera = req.headers.authorization || '';
  const token = cabecera.startsWith('Bearer ') ? cabecera.slice(7) : '';
  try {
    const datos = jwt.verify(token, JWT_SECRET);
    req.user = { id: datos.id, nombre: datos.nombre };
    next();
  } catch (_) {
    res.status(401).json({ mensaje: 'Sesión no válida, inicia sesión otra vez' });
  }
}

// Solo el administrador del juego puede ver las métricas del servidor
async function soloAdmin(req, res, next) {
  try {
    const [f] = await pool.execute('SELECT rol FROM usuarios WHERE id_usuario = ?', [req.user.id]);
    if (f.length && f[0].rol === 'admin') return next();
    res.status(403).json({ mensaje: 'Solo el administrador puede ver esta información' });
  } catch (e) {
    next(e);
  }
}

function crearToken(id, nombre) {
  return jwt.sign({ id, nombre }, JWT_SECRET, { expiresIn: '7d' });
}

// Datos del jugador que necesita la app: nivel desbloqueado y mejores puntajes
async function perfil(idUsuario, nombre) {
  const [filas] = await pool.execute(
    `SELECT id_nivel, MAX(puntaje) AS mejor
       FROM partidas
      WHERE id_usuario = ? AND resultado = 'ganada'
      GROUP BY id_nivel`,
    [idUsuario]
  );
  const mejoresPuntajes = {};
  let nivelMaximoGanado = 0;
  for (const f of filas) {
    mejoresPuntajes[f.id_nivel] = Number(f.mejor);
    if (f.id_nivel > nivelMaximoGanado) nivelMaximoGanado = f.id_nivel;
  }
  const [r] = await pool.execute('SELECT rol FROM usuarios WHERE id_usuario = ?', [idUsuario]);
  return {
    id: idUsuario,
    usuario: nombre,
    rol: r.length ? r[0].rol : 'jugador',
    nivelDesbloqueado: Math.min(3, nivelMaximoGanado + 1),
    mejoresPuntajes,
  };
}

const entero = (v) => (Number.isInteger(v) && v >= 0 ? v : null);

app.get('/api/salud', ah(async (req, res) => {
  await pool.query('SELECT 1');
  res.json({ ok: true });
}));

// ---------- Registro e inicio de sesión ----------
app.post('/api/registro', ah(async (req, res) => {
  const usuario = String(req.body.usuario || '').trim();
  const contrasena = String(req.body.contrasena || '');
  const correo = req.body.correo ? String(req.body.correo).trim() : null;

  if (usuario.length < 3 || usuario.length > 50) {
    return res.status(400).json({ mensaje: 'El usuario debe tener entre 3 y 50 caracteres' });
  }
  if (contrasena.length < 4 || contrasena.length > 72) {
    return res.status(400).json({ mensaje: 'La contraseña debe tener al menos 4 caracteres' });
  }
  const hash = await bcrypt.hash(contrasena, 10);
  try {
    const [r] = await pool.execute(
      'INSERT INTO usuarios (nombre_usuario, correo, contrasena_hash) VALUES (?, ?, ?)',
      [usuario, correo, hash]
    );
    res.status(201).json({
      mensaje: 'Registro exitoso',
      token: crearToken(r.insertId, usuario),
      usuario: await perfil(r.insertId, usuario),
    });
  } catch (e) {
    if (e.code === 'ER_DUP_ENTRY') {
      const msg = String(e.sqlMessage || '').includes('correo')
        ? 'Ese correo ya está registrado'
        : 'El usuario ya existe';
      return res.status(409).json({ mensaje: msg });
    }
    throw e;
  }
}));

app.post('/api/login', ah(async (req, res) => {
  const usuario = String(req.body.usuario || '').trim();
  const contrasena = String(req.body.contrasena || '');
  if (!usuario || !contrasena) {
    return res.status(400).json({ mensaje: 'Complete todos los campos' });
  }
  const [filas] = await pool.execute(
    'SELECT id_usuario, nombre_usuario, contrasena_hash FROM usuarios WHERE nombre_usuario = ?',
    [usuario]
  );
  if (filas.length === 0) {
    return res.status(404).json({ mensaje: 'Usuario no encontrado' });
  }
  const u = filas[0];
  if (!(await bcrypt.compare(contrasena, u.contrasena_hash))) {
    return res.status(401).json({ mensaje: 'Contraseña incorrecta' });
  }
  res.json({
    mensaje: 'Bienvenido',
    token: crearToken(u.id_usuario, u.nombre_usuario),
    usuario: await perfil(u.id_usuario, u.nombre_usuario),
  });
}));

app.get('/api/usuarios/me', auth, ah(async (req, res) => {
  res.json(await perfil(req.user.id, req.user.nombre));
}));

// Cambiar la contraseña desde Configuración
app.post('/api/usuarios/me/contrasena', auth, ah(async (req, res) => {
  const actual = String(req.body.actual || '');
  const nueva = String(req.body.nueva || '');
  if (!actual || !nueva) {
    return res.status(400).json({ mensaje: 'Complete todos los campos' });
  }
  if (nueva.length < 4 || nueva.length > 72) {
    return res.status(400).json({ mensaje: 'La contraseña nueva debe tener entre 4 y 72 caracteres' });
  }
  const [filas] = await pool.execute(
    'SELECT contrasena_hash FROM usuarios WHERE id_usuario = ?',
    [req.user.id]
  );
  if (filas.length === 0) {
    return res.status(404).json({ mensaje: 'Usuario no encontrado' });
  }
  if (!(await bcrypt.compare(actual, filas[0].contrasena_hash))) {
    return res.status(401).json({ mensaje: 'La contraseña actual es incorrecta' });
  }
  const hash = await bcrypt.hash(nueva, 10);
  await pool.execute('UPDATE usuarios SET contrasena_hash = ? WHERE id_usuario = ?', [hash, req.user.id]);
  res.json({ mensaje: 'Contraseña actualizada' });
}));

// ---------- Niveles ----------
app.get('/api/niveles', ah(async (req, res) => {
  const [filas] = await pool.query(
    `SELECT id_nivel AS nivel, nombre, dificultad, num_parejas AS parejas,
            tiempo_limite_seg AS tiempo
       FROM niveles ORDER BY id_nivel`
  );
  res.json(filas);
}));

// ---------- Partidas ----------
app.post('/api/partidas', auth, ah(async (req, res) => {
  const b = req.body || {};
  const nivel = entero(b.nivel);
  const puntaje = entero(b.puntaje);
  const errores = entero(b.errores);
  const intentos = entero(b.intentos);
  const parejas = entero(b.parejas);
  const duracion = entero(b.duracion);
  const resultado = b.resultado;
  const modo = b.modo === 'departamentos' ? 'departamentos' : 'simbolos';

  if ([nivel, puntaje, errores, intentos, parejas, duracion].includes(null) ||
      !['ganada', 'perdida'].includes(resultado)) {
    return res.status(400).json({ mensaje: 'Datos de la partida incompletos o no válidos' });
  }
  const [niv] = await pool.execute(
    'SELECT num_parejas, tiempo_limite_seg FROM niveles WHERE id_nivel = ?',
    [nivel]
  );
  if (niv.length === 0) {
    return res.status(400).json({ mensaje: 'Ese nivel no existe' });
  }
  const { num_parejas, tiempo_limite_seg } = niv[0];

  // Revisión básica para que no se guarden puntajes imposibles
  const maximo = num_parejas * 100 + tiempo_limite_seg * 5;
  if (parejas > num_parejas || duracion > tiempo_limite_seg + 5 || puntaje > maximo ||
      (resultado === 'ganada' && parejas !== num_parejas)) {
    return res.status(400).json({ mensaje: 'La partida no es válida para ese nivel' });
  }
  const puntajeFinal = resultado === 'ganada' ? puntaje : 0;

  const [r] = await pool.execute(
    `INSERT INTO partidas
       (id_usuario, id_nivel, resultado, puntaje, errores, intentos, parejas_encontradas, duracion_seg, modo)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [req.user.id, nivel, resultado, puntajeFinal, errores, intentos, parejas, duracion, modo]
  );
  res.status(201).json({
    mensaje: 'Partida guardada',
    idPartida: r.insertId,
    usuario: await perfil(req.user.id, req.user.nombre),
  });
}));

app.get('/api/usuarios/me/estadisticas', auth, ah(async (req, res) => {
  const [filas] = await pool.execute(
    'SELECT partidas_jugadas, ganadas, perdidas, promedio_victorias FROM vw_estadisticas_usuario WHERE id_usuario = ?',
    [req.user.id]
  );
  const f = filas[0] || {};
  const p = await perfil(req.user.id, req.user.nombre);
  res.json({
    intentos: Number(f.partidas_jugadas || 0),
    ganadas: Number(f.ganadas || 0),
    perdidas: Number(f.perdidas || 0),
    promedioVictorias: Number(f.promedio_victorias || 0),
    nivelDesbloqueado: p.nivelDesbloqueado,
    mejoresPuntajes: p.mejoresPuntajes,
  });
}));

// ---------- Ranking ----------
app.get('/api/ranking', ah(async (req, res) => {
  const nivel = req.query.nivel ? Number(req.query.nivel) : null;
  if (nivel !== null && ![1, 2, 3].includes(nivel)) {
    return res.status(400).json({ mensaje: 'Nivel no válido' });
  }
  const filtro = nivel ? 'AND id_nivel = ?' : '';
  const [filas] = await pool.execute(
    `SELECT u.nombre_usuario AS usuario, SUM(m.mejor) AS puntaje
       FROM (SELECT id_usuario, id_nivel, MAX(puntaje) AS mejor
               FROM partidas
              WHERE resultado = 'ganada' ${filtro}
              GROUP BY id_usuario, id_nivel) m
       JOIN usuarios u ON u.id_usuario = m.id_usuario
      GROUP BY u.id_usuario, u.nombre_usuario
      ORDER BY puntaje DESC, u.nombre_usuario ASC
      LIMIT 20`,
    nivel ? [nivel] : []
  );
  res.json(filas.map((f, i) => ({ posicion: i + 1, usuario: f.usuario, puntaje: Number(f.puntaje) })));
}));

// ---------- Símbolos y datos curiosos (la IA corre aquí, en el servidor) ----------
const comoLista = (v) => (typeof v === 'string' ? JSON.parse(v) : v) || [];

app.get('/api/simbolos', ah(async (req, res) => {
  const [filas] = await pool.query(
    'SELECT clave, nombre, descripcion, imagen, datos_curiosos FROM simbolos ORDER BY id_simbolo'
  );
  res.json(filas.map((f) => ({
    clave: f.clave,
    nombre: f.nombre,
    descripcion: f.descripcion,
    imagen: f.imagen,
    datos: comoLista(f.datos_curiosos),
  })));
}));

async function narrarConIA(simbolo, datos, tipo = 'símbolo patrio') {
  const key = process.env.GEMINI_API_KEY;
  const modelo = process.env.GEMINI_MODEL;
  if (!key || !modelo) return null;
  const lista = datos.map((d) => `- ${d}`).join('\n');
  const prompt =
    'Eres el narrador del juego de memoria "Memory Honduras", para estudiantes. ' +
    `El jugador acaba de encontrar el par de este elemento (${tipo}): "${simbolo.nombre}" (${simbolo.descripcion}).\n` +
    'Elige AL AZAR UNO de estos tres datos y cuéntaselo en UNA sola frase breve ' +
    '(máximo 22 palabras), en español, con tono amigable. No enumeres ni repitas la lista:\n' +
    `${lista}\nResponde únicamente con la frase, sin comillas.`;
  try {
    const r = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${modelo}:generateContent`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 1.0, maxOutputTokens: 120 },
        }),
        signal: AbortSignal.timeout(8000),
      }
    );
    if (!r.ok) return null;
    const data = await r.json();
    const texto = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    return texto && texto.trim() ? texto.trim() : null;
  } catch (_) {
    return null;
  }
}

app.get('/api/simbolos/:clave/dato', auth, ah(async (req, res) => {
  const [filas] = await pool.execute(
    'SELECT nombre, descripcion, datos_curiosos FROM simbolos WHERE clave = ?',
    [req.params.clave]
  );
  if (filas.length === 0) {
    return res.status(404).json({ mensaje: 'Símbolo no encontrado' });
  }
  const s = filas[0];
  const datos = comoLista(s.datos_curiosos);
  const deIA = await narrarConIA(s, datos);
  if (deIA) return res.json({ texto: deIA, ia: true });
  const respaldo = datos.length
    ? datos[Math.floor(Math.random() * datos.length)]
    : s.descripcion;
  res.json({ texto: respaldo, ia: false });
}));

// ---------- Tienda con pago simulado ----------
// El pago es una simulación: nunca se guarda el número completo de la tarjeta,
// solo los últimos 4 dígitos y una referencia de la operación.
app.get('/api/tienda/productos', ah(async (req, res) => {
  const [filas] = await pool.query(
    `SELECT clave, nombre, descripcion, precio, icono, repetible
       FROM productos WHERE activo = 1 ORDER BY id_producto`
  );
  res.json(filas.map((p) => ({
    clave: p.clave, nombre: p.nombre, descripcion: p.descripcion,
    precio: Number(p.precio), icono: p.icono, repetible: p.repetible === 1,
  })));
}));

app.get('/api/tienda/mis-compras', auth, ah(async (req, res) => {
  const [filas] = await pool.execute(
    `SELECT p.clave, p.nombre, c.monto, c.metodo, c.referencia,
            DATE_FORMAT(c.fecha_compra, '%Y-%m-%d %H:%i') AS fecha
       FROM compras c JOIN productos p ON p.id_producto = c.id_producto
      WHERE c.id_usuario = ? AND c.estado = 'aprobada'
      ORDER BY c.id_compra DESC`,
    [req.user.id]
  );
  res.json(filas.map((f) => ({
    clave: f.clave, nombre: f.nombre, monto: Number(f.monto),
    metodo: f.metodo, referencia: f.referencia, fecha: f.fecha,
  })));
}));

app.post('/api/tienda/comprar', auth, ah(async (req, res) => {
  const { clave, metodo } = req.body || {};
  let { ultimos4 } = req.body || {};
  if (typeof clave !== 'string' || !['tarjeta', 'paypal'].includes(metodo)) {
    return res.status(400).json({ mensaje: 'Datos de compra no válidos' });
  }
  if (metodo === 'paypal') ultimos4 = '0000';
  if (typeof ultimos4 !== 'string' || !/^\d{4}$/.test(ultimos4)) {
    return res.status(400).json({ mensaje: 'Datos de pago no válidos' });
  }
  const [prod] = await pool.execute(
    'SELECT id_producto, nombre, precio, repetible FROM productos WHERE clave = ? AND activo = 1',
    [clave]
  );
  if (prod.length === 0) {
    return res.status(404).json({ mensaje: 'Producto no encontrado' });
  }
  const p = prod[0];
  if (p.repetible !== 1) {
    const [ya] = await pool.execute(
      `SELECT 1 FROM compras WHERE id_usuario = ? AND id_producto = ? AND estado = 'aprobada' LIMIT 1`,
      [req.user.id, p.id_producto]
    );
    if (ya.length > 0) {
      return res.status(409).json({ mensaje: 'Ya tienes este producto' });
    }
  }
  const referencia = 'MH-' + new Date().toISOString().slice(2, 10).replace(/-/g, '') +
    '-' + require('crypto').randomBytes(3).toString('hex').toUpperCase();
  await pool.execute(
    `INSERT INTO compras (id_usuario, id_producto, monto, metodo, ultimos4, referencia, estado)
     VALUES (?, ?, ?, ?, ?, ?, 'aprobada')`,
    [req.user.id, p.id_producto, p.precio, metodo, ultimos4, referencia]
  );
  res.status(201).json({
    mensaje: 'Pago simulado aprobado',
    referencia, producto: p.nombre, monto: Number(p.precio),
  });
}));

// ---------- Departamentos de Honduras ----------
app.get('/api/departamentos', ah(async (req, res) => {
  const [filas] = await pool.query(
    'SELECT clave, nombre, cabecera, datos_curiosos FROM departamentos ORDER BY nombre'
  );
  res.json(filas.map((f) => ({
    clave: f.clave,
    nombre: f.nombre,
    cabecera: f.cabecera,
    datos: comoLista(f.datos_curiosos),
  })));
}));

app.get('/api/departamentos/:clave/dato', auth, ah(async (req, res) => {
  const [filas] = await pool.execute(
    'SELECT nombre, cabecera, datos_curiosos FROM departamentos WHERE clave = ?',
    [req.params.clave]
  );
  if (filas.length === 0) {
    return res.status(404).json({ mensaje: 'Departamento no encontrado' });
  }
  const d = filas[0];
  const datos = comoLista(d.datos_curiosos);
  const deIA = await narrarConIA(
    { nombre: d.nombre, descripcion: `Departamento de Honduras, cabecera ${d.cabecera}` },
    datos,
    'departamento de Honduras'
  );
  if (deIA) return res.json({ texto: deIA, ia: true });
  const texto = datos.length
    ? datos[Math.floor(Math.random() * datos.length)]
    : `Cabecera departamental: ${d.cabecera}.`;
  res.json({ texto, ia: false });
}));

// ---------- Panel de monitoreo del servidor ----------
app.get('/api/metricas', auth, soloAdmin, ah(async (req, res) => {
  const [[u]] = await pool.query('SELECT COUNT(*) AS total FROM usuarios');
  const [[p]] = await pool.query(
    `SELECT COUNT(*) AS total,
            COALESCE(SUM(resultado = 'ganada'), 0) AS ganadas,
            COALESCE(SUM(resultado = 'perdida'), 0) AS perdidas,
            COALESCE(ROUND(AVG(duracion_seg)), 0) AS duracion_prom,
            COALESCE(SUM(duracion_seg), 0) AS segundos_total
       FROM partidas`
  );
  const [porNivel] = await pool.query(
    `SELECT n.id_nivel AS nivel, n.nombre, n.dificultad,
            COUNT(p.id_partida) AS jugadas,
            COALESCE(SUM(p.resultado = 'ganada'), 0) AS ganadas,
            COALESCE(SUM(p.resultado = 'perdida'), 0) AS perdidas,
            COALESCE(MAX(p.puntaje), 0) AS mejor_puntaje,
            COALESCE(ROUND(AVG(CASE WHEN p.resultado = 'ganada' THEN p.puntaje END)), 0) AS puntaje_prom,
            COALESCE(ROUND(AVG(p.duracion_seg)), 0) AS duracion_prom
       FROM niveles n
       LEFT JOIN partidas p ON p.id_nivel = n.id_nivel
      GROUP BY n.id_nivel, n.nombre, n.dificultad
      ORDER BY n.id_nivel`
  );
  const [partidasDia] = await pool.query(
    `SELECT DATE_FORMAT(fecha_partida, '%Y-%m-%d') AS dia, COUNT(*) AS total
       FROM partidas
      WHERE fecha_partida >= CURDATE() - INTERVAL 6 DAY
      GROUP BY dia ORDER BY dia`
  );
  const [usuariosDia] = await pool.query(
    `SELECT DATE_FORMAT(fecha_registro, '%Y-%m-%d') AS dia, COUNT(*) AS total
       FROM usuarios
      WHERE fecha_registro >= CURDATE() - INTERVAL 6 DAY
      GROUP BY dia ORDER BY dia`
  );
  const [[v]] = await pool.query(
    `SELECT COUNT(*) AS total, COALESCE(SUM(monto), 0) AS ingresos
       FROM compras WHERE estado = 'aprobada'`
  );
  const [ventasProd] = await pool.query(
    `SELECT p.nombre, COUNT(c.id_compra) AS cantidad, COALESCE(SUM(c.monto), 0) AS ingresos
       FROM productos p LEFT JOIN compras c ON c.id_producto = p.id_producto AND c.estado = 'aprobada'
      GROUP BY p.id_producto, p.nombre ORDER BY p.id_producto`
  );
  const [ventasRec] = await pool.query(
    `SELECT u.nombre_usuario AS usuario, p.nombre AS producto, c.monto, c.metodo,
            DATE_FORMAT(c.fecha_compra, '%d/%m %H:%i') AS fecha
       FROM compras c
       JOIN usuarios u ON u.id_usuario = c.id_usuario
       JOIN productos p ON p.id_producto = c.id_producto
      WHERE c.estado = 'aprobada' ORDER BY c.id_compra DESC LIMIT 5`
  );
  const [porModo] = await pool.query(
    `SELECT modo, COUNT(*) AS jugadas, COALESCE(SUM(resultado = 'ganada'), 0) AS ganadas
       FROM partidas GROUP BY modo`
  );
  const totalMB = Math.round(os.totalmem() / 1048576);
  const libreMB = Math.round(os.freemem() / 1048576);
  const n = (v) => Number(v || 0);
  res.json({
    usuarios: n(u.total),
    partidas: {
      total: n(p.total),
      ganadas: n(p.ganadas),
      perdidas: n(p.perdidas),
      duracionPromedioSeg: n(p.duracion_prom),
      tiempoJugadoSeg: n(p.segundos_total),
    },
    porNivel: porNivel.map((f) => ({
      nivel: f.nivel, nombre: f.nombre, dificultad: f.dificultad,
      jugadas: n(f.jugadas), ganadas: n(f.ganadas), perdidas: n(f.perdidas),
      mejorPuntaje: n(f.mejor_puntaje), puntajePromedio: n(f.puntaje_prom),
      duracionPromedioSeg: n(f.duracion_prom),
    })),
    ventas: {
      total: n(v.total),
      ingresos: Number(v.ingresos || 0),
      porProducto: ventasProd.map((f) => ({ nombre: f.nombre, cantidad: n(f.cantidad), ingresos: Number(f.ingresos || 0) })),
      recientes: ventasRec.map((f) => ({ usuario: f.usuario, producto: f.producto, monto: Number(f.monto), metodo: f.metodo, fecha: f.fecha })),
    },
    porModo: porModo.map((f) => ({ modo: f.modo, jugadas: n(f.jugadas), ganadas: n(f.ganadas) })),
    partidasPorDia: partidasDia.map((f) => ({ dia: f.dia, total: n(f.total) })),
    usuariosPorDia: usuariosDia.map((f) => ({ dia: f.dia, total: n(f.total) })),
    servidor: {
      sistema: `${os.type()} ${os.release()}`,
      equipo: os.hostname(),
      node: process.version,
      cpus: os.cpus().length,
      cargaCpu: Number(os.loadavg()[0].toFixed(2)),
      memoriaTotalMB: totalMB,
      memoriaLibreMB: libreMB,
      encendidoSeg: Math.round(os.uptime()),
      apiActivaSeg: Math.round(process.uptime()),
      iaConfigurada: Boolean(process.env.GEMINI_API_KEY && process.env.GEMINI_MODEL),
    },
    generado: new Date().toISOString(),
  });
}));

app.get('/', (req, res) => res.redirect('/panel'));
app.get('/panel', (req, res) =>
  res.sendFile(path.join(__dirname, 'public', 'panel.html'))
);

// ---------- Errores ----------
app.use((req, res) => res.status(404).json({ mensaje: 'Ruta no encontrada' }));
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ mensaje: 'Error del servidor' });
});

const puerto = Number(process.env.PORT) || 3000;
app.listen(puerto, '0.0.0.0', () => console.log(`API de Memory Honduras en el puerto ${puerto}`));
