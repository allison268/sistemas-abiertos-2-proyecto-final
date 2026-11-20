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
// Detrás de ngrok la conexión llega como http, pero el usuario usa https.
// Con esto Express usa el protocolo y la dirección reales (sirve para PayPal).
app.set('trust proxy', true);
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

// ---------- IA (Google Gemini) ----------
// Función única para hablar con Gemini. La usan los datos curiosos y el
// asistente del administrador. Si el modelo principal está ocupado (error 503)
// o falla, prueba con el modelo de respaldo. Si ninguno responde, devuelve null
// y quien la llamó usa su propio respaldo, así el juego nunca se rompe.
function modelosIA() {
  const lista = [
    process.env.GEMINI_MODEL,
    process.env.GEMINI_MODEL_RESPALDO || 'gemini-flash-lite-latest',
  ].filter(Boolean);
  return [...new Set(lista)];
}

const iaConfigurada = () => Boolean(process.env.GEMINI_API_KEY && modelosIA().length);

async function llamarGemini(prompt, { temperatura = 0.7, maxTokens = 800, esperaMs = 15000 } = {}) {
  const key = process.env.GEMINI_API_KEY;
  if (!key) return null;
  for (const modelo of modelosIA()) {
    try {
      const r = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${modelo}:generateContent`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: { temperature: temperatura, maxOutputTokens: maxTokens },
          }),
          signal: AbortSignal.timeout(esperaMs),
        }
      );
      if (!r.ok) {
        console.warn(`Gemini (${modelo}) respondió ${r.status}, probando el siguiente modelo`);
        continue;
      }
      const data = await r.json();
      const partes = data?.candidates?.[0]?.content?.parts || [];
      const texto = partes.map((p) => p.text || '').join('').trim();
      if (texto) return texto;
    } catch (e) {
      console.warn(`Gemini (${modelo}) no respondió: ${e.message}`);
    }
  }
  return null;
}

async function narrarConIA(simbolo, datos, tipo = 'símbolo patrio') {
  const lista = datos.map((d) => `- ${d}`).join('\n');
  const prompt =
    'Eres el narrador del juego de memoria "Memory Honduras", para estudiantes. ' +
    `El jugador acaba de encontrar el par de este elemento (${tipo}): "${simbolo.nombre}" (${simbolo.descripcion}).\n` +
    'Elige AL AZAR UNO de estos tres datos y cuéntaselo en UNA sola frase breve ' +
    '(máximo 22 palabras), en español, con tono amigable. No enumeres ni repitas la lista. ' +
    'No empieces con "Dato curioso" ni con un título; ve directo al dato:\n' +
    `${lista}\nResponde únicamente con la frase, sin comillas.`;
  const texto = await llamarGemini(prompt, { temperatura: 1.0, maxTokens: 300, esperaMs: 8000 });
  // Por si la IA igual empieza con "¡Dato curioso!" o "Dato curioso:", se quita.
  return texto ? texto.replace(/^\s*[¡!]?\s*dato curioso\s*[!:.,\-–—]*\s*/i, '').trim() || null : null;
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

// ---------- Pago real con PayPal ----------
// Flujo:
//  1. La app pide crear una orden (/api/paypal/crear-orden).
//  2. El servidor crea la orden en PayPal y le devuelve a la app el enlace de pago.
//  3. El jugador paga en la página oficial de PayPal (con su cuenta o con tarjeta).
//  4. PayPal lo regresa a /api/paypal/retorno; el servidor confirma (captura) el
//     cobro con PayPal y guarda la compra en MySQL.
//  5. Mientras tanto la app pregunta cada pocos segundos /api/paypal/orden/:id.
// Los datos de la tarjeta se escriben SOLO en la página de PayPal: nunca pasan
// por la app ni por este servidor.
// PayPal no acepta lempiras, así que se cobra el equivalente en dólares.
const PAYPAL_API = process.env.PAYPAL_API_URL || (process.env.PAYPAL_MODE === 'live'
  ? 'https://api-m.paypal.com'
  : 'https://api-m.sandbox.paypal.com');
const paypalConfigurado = () =>
  Boolean(process.env.PAYPAL_CLIENT_ID && process.env.PAYPAL_CLIENT_SECRET);
const LEMPIRAS_POR_DOLAR = Number(process.env.LEMPIRAS_POR_DOLAR) || 27.07;

let paypalToken = { valor: null, vence: 0 };
async function tokenPayPal() {
  if (paypalToken.valor && Date.now() < paypalToken.vence) return paypalToken.valor;
  const credenciales = Buffer.from(
    `${process.env.PAYPAL_CLIENT_ID}:${process.env.PAYPAL_CLIENT_SECRET}`
  ).toString('base64');
  const r = await fetch(`${PAYPAL_API}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${credenciales}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
    signal: AbortSignal.timeout(15000),
  });
  if (!r.ok) throw new Error(`PayPal no aceptó las credenciales (${r.status})`);
  const data = await r.json();
  paypalToken = { valor: data.access_token, vence: Date.now() + (data.expires_in - 60) * 1000 };
  return paypalToken.valor;
}

async function pedirPayPal(metodoHttp, ruta, cuerpo) {
  const r = await fetch(`${PAYPAL_API}${ruta}`, {
    method: metodoHttp,
    headers: {
      Authorization: `Bearer ${await tokenPayPal()}`,
      'Content-Type': 'application/json',
    },
    body: cuerpo ? JSON.stringify(cuerpo) : undefined,
    signal: AbortSignal.timeout(20000),
  });
  const data = await r.json().catch(() => ({}));
  return { ok: r.ok, status: r.status, data };
}

// URL pública de este servidor (la misma que usó la app para llamarnos).
function urlServidor(req) {
  return (process.env.PUBLIC_URL || `${req.protocol}://${req.get('host')}`).replace(/\/$/, '');
}

function paginaPago(titulo, mensaje, exito) {
  const color = exito ? '#2E7D32' : '#C62828';
  const icono = exito ? '✔' : '✖';
  return `<!DOCTYPE html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>${titulo}</title>
<style>body{font-family:system-ui,sans-serif;background:#F4F7FF;display:flex;align-items:center;
justify-content:center;min-height:100vh;margin:0}.c{background:#fff;border-radius:20px;padding:32px;
max-width:420px;text-align:center;box-shadow:0 6px 24px #0033a022}.i{width:72px;height:72px;border-radius:50%;
background:${color};color:#fff;font-size:40px;line-height:72px;margin:0 auto 12px}h1{color:${color};margin:8px 0}
p{color:#5C6B8A}</style></head><body><div class="c"><div class="i">${icono}</div>
<h1>${titulo}</h1><p>${mensaje}</p><p><b>Ya puedes cerrar esta pestaña y volver a Memory Honduras.</b></p>
</div></body></html>`;
}

app.get('/api/paypal/config', (req, res) => {
  res.json({
    activo: paypalConfigurado(),
    modo: process.env.PAYPAL_MODE === 'live' ? 'live' : 'sandbox',
    lempirasPorDolar: LEMPIRAS_POR_DOLAR,
  });
});

app.post('/api/paypal/crear-orden', auth, ah(async (req, res) => {
  if (!paypalConfigurado()) {
    return res.status(503).json({ mensaje: 'PayPal no está configurado en el servidor' });
  }
  const { clave, metodo } = req.body || {};
  if (typeof clave !== 'string' || !['tarjeta', 'paypal'].includes(metodo)) {
    return res.status(400).json({ mensaje: 'Datos de compra no válidos' });
  }
  const [prod] = await pool.execute(
    'SELECT id_producto, nombre, precio, repetible FROM productos WHERE clave = ? AND activo = 1',
    [clave]
  );
  if (prod.length === 0) return res.status(404).json({ mensaje: 'Producto no encontrado' });
  const p = prod[0];
  if (p.repetible !== 1) {
    const [ya] = await pool.execute(
      `SELECT 1 FROM compras WHERE id_usuario = ? AND id_producto = ? AND estado = 'aprobada' LIMIT 1`,
      [req.user.id, p.id_producto]
    );
    if (ya.length > 0) return res.status(409).json({ mensaje: 'Ya tienes este producto' });
  }
  const montoUsd = Math.max(0.01, Math.round((Number(p.precio) / LEMPIRAS_POR_DOLAR) * 100) / 100).toFixed(2);
  const base = urlServidor(req);
  const orden = await pedirPayPal('POST', '/v2/checkout/orders', {
    intent: 'CAPTURE',
    purchase_units: [{
      reference_id: clave,
      description: `Memory Honduras - ${p.nombre}`.slice(0, 127),
      custom_id: `${req.user.id}:${p.id_producto}`,
      amount: { currency_code: 'USD', value: montoUsd },
    }],
    payment_source: {
      paypal: {
        experience_context: {
          brand_name: 'Memory Honduras',
          // 'GUEST_CHECKOUT' abre directo el formulario de tarjeta de PayPal.
          landing_page: metodo === 'tarjeta' ? 'GUEST_CHECKOUT' : 'LOGIN',
          shipping_preference: 'NO_SHIPPING',
          user_action: 'PAY_NOW',
          return_url: `${base}/api/paypal/retorno`,
          cancel_url: `${base}/api/paypal/cancelado`,
        },
      },
    },
  });
  const enlace = (orden.data.links || []).find((l) => l.rel === 'payer-action' || l.rel === 'approve');
  if (!orden.ok || !orden.data.id || !enlace) {
    console.error('PayPal no creó la orden:', orden.status, JSON.stringify(orden.data));
    return res.status(502).json({ mensaje: 'PayPal no pudo crear el pago, intenta de nuevo' });
  }
  await pool.execute(
    `INSERT INTO pagos_paypal (id_orden, id_usuario, id_producto, metodo, monto_hnl, monto_usd)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [orden.data.id, req.user.id, p.id_producto, metodo, p.precio, montoUsd]
  );
  res.status(201).json({
    orden: orden.data.id,
    url: enlace.href,
    montoUsd: Number(montoUsd),
    modo: process.env.PAYPAL_MODE === 'live' ? 'live' : 'sandbox',
  });
}));

// PayPal regresa aquí al jugador después de aprobar el pago.
app.get('/api/paypal/retorno', ah(async (req, res) => {
  const idOrden = String(req.query.token || '');
  const [filas] = await pool.execute('SELECT * FROM pagos_paypal WHERE id_orden = ?', [idOrden]);
  if (filas.length === 0) {
    return res.status(404).send(paginaPago('Pago no encontrado', 'No reconocemos esta orden de pago.', false));
  }
  const pago = filas[0];
  if (pago.estado === 'completada') {
    return res.send(paginaPago('¡Pago aprobado!', `Referencia: ${pago.referencia}`, true));
  }
  // Se "aparta" la orden para que recargar la página no cobre dos veces.
  const [apartada] = await pool.execute(
    `UPDATE pagos_paypal SET estado = 'procesando' WHERE id_orden = ? AND estado = 'creada'`,
    [idOrden]
  );
  if (apartada.affectedRows !== 1) {
    return res.send(paginaPago('Pago en proceso', 'Tu pago ya se está procesando.', true));
  }
  let cobro;
  try {
    cobro = await pedirPayPal('POST', `/v2/checkout/orders/${encodeURIComponent(idOrden)}/capture`, {});
  } catch (e) {
    cobro = { ok: false, status: 0, data: { message: e.message } };
  }
  const captura = cobro.data?.purchase_units?.[0]?.payments?.captures?.[0];
  const cobrado = Number(captura?.amount?.value);
  if (!cobro.ok || cobro.data.status !== 'COMPLETED' || !captura ||
      captura.status !== 'COMPLETED' || cobrado !== Number(pago.monto_usd)) {
    const detalle = (cobro.data?.details?.[0]?.issue || cobro.data?.message || `HTTP ${cobro.status}`).toString().slice(0, 250);
    console.error('PayPal no completó el cobro:', idOrden, detalle);
    await pool.execute(
      `UPDATE pagos_paypal SET estado = 'fallida', detalle = ? WHERE id_orden = ?`,
      [detalle, idOrden]
    );
    return res.send(paginaPago('Pago rechazado', 'PayPal no pudo completar el cobro. No se te cobró nada.', false));
  }
  const referencia = String(captura.id).slice(0, 24);
  await pool.execute(
    `INSERT INTO compras (id_usuario, id_producto, monto, metodo, ultimos4, referencia, estado)
     VALUES (?, ?, ?, ?, '0000', ?, 'aprobada')`,
    [pago.id_usuario, pago.id_producto, pago.monto_hnl, pago.metodo, referencia]
  );
  await pool.execute(
    `UPDATE pagos_paypal SET estado = 'completada', referencia = ? WHERE id_orden = ?`,
    [referencia, idOrden]
  );
  res.send(paginaPago('¡Pago aprobado!', `Referencia de PayPal: ${referencia}`, true));
}));

app.get('/api/paypal/cancelado', ah(async (req, res) => {
  await pool.execute(
    `UPDATE pagos_paypal SET estado = 'cancelada' WHERE id_orden = ? AND estado = 'creada'`,
    [String(req.query.token || '')]
  );
  res.send(paginaPago('Pago cancelado', 'Cancelaste el pago. No se te cobró nada.', false));
}));

// La app pregunta aquí cómo va su pago.
app.get('/api/paypal/orden/:id', auth, ah(async (req, res) => {
  const [filas] = await pool.execute(
    `SELECT pp.estado, pp.referencia, pp.metodo, pp.monto_hnl, pp.monto_usd, p.nombre
       FROM pagos_paypal pp JOIN productos p ON p.id_producto = pp.id_producto
      WHERE pp.id_orden = ? AND pp.id_usuario = ?`,
    [req.params.id, req.user.id]
  );
  if (filas.length === 0) return res.status(404).json({ mensaje: 'Pago no encontrado' });
  const f = filas[0];
  res.json({
    estado: f.estado, referencia: f.referencia, metodo: f.metodo,
    producto: f.nombre, monto: Number(f.monto_hnl), montoUsd: Number(f.monto_usd),
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
// Reúne todas las métricas del juego y del servidor en un solo objeto.
// La usan el panel (/api/metricas) y el asistente de IA del administrador.
async function obtenerMetricas() {
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
  const [ultimas] = await pool.query(
    `SELECT resultado FROM partidas ORDER BY id_partida DESC LIMIT 10`
  );
  let pagosFallidos = 0;
  try {
    const [[pf]] = await pool.query(
      `SELECT COUNT(*) AS total FROM pagos_paypal
        WHERE estado = 'fallida' AND fecha_creada >= NOW() - INTERVAL 1 DAY`
    );
    pagosFallidos = Number(pf.total || 0);
  } catch (_) { /* la tabla de PayPal aún no existe */ }
  const totalMB = Math.round(os.totalmem() / 1048576);
  const libreMB = Math.round(os.freemem() / 1048576);
  const n = (v) => Number(v || 0);
  const metricas = {
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
      iaConfigurada: iaConfigurada(),
    },
    generado: new Date().toISOString(),
  };
  metricas.alertas = calcularAlertas(metricas, {
    ultimas: ultimas.map((f) => f.resultado),
    pagosFallidos,
  });
  return metricas;
}

// ---------- Alertas del panel ----------
// Reglas sencillas que revisan las métricas cada vez que el panel se actualiza
// (cada 5 segundos). No gastan IA: la IA solo se usa si el administrador pide
// un consejo sobre las alertas.
function calcularAlertas(m, { ultimas, pagosFallidos }) {
  const alertas = [];
  const s = m.servidor;
  const usoMemoria = s.memoriaTotalMB ? 1 - s.memoriaLibreMB / s.memoriaTotalMB : 0;
  if (usoMemoria >= 0.85) {
    alertas.push({
      nivel: 'alta',
      titulo: 'Memoria del servidor casi llena',
      detalle: `Rocky está usando el ${Math.round(usoMemoria * 100)}% de la memoria RAM.`,
    });
  }
  if (s.cargaCpu > s.cpus) {
    alertas.push({
      nivel: 'alta',
      titulo: 'Procesador muy ocupado',
      detalle: `La carga del CPU es ${s.cargaCpu} y el servidor tiene ${s.cpus} procesadores.`,
    });
  }
  if (!s.iaConfigurada) {
    alertas.push({
      nivel: 'media',
      titulo: 'La IA no está configurada',
      detalle: 'Falta GEMINI_API_KEY en el archivo .env; se usan los datos guardados.',
    });
  }
  for (const nv of m.porNivel) {
    if (nv.jugadas >= 5 && nv.ganadas / nv.jugadas < 0.3) {
      alertas.push({
        nivel: 'media',
        titulo: `El Nivel ${nv.nivel} parece muy difícil`,
        detalle: `Solo se ganó ${nv.ganadas} de ${nv.jugadas} partidas (${Math.round((100 * nv.ganadas) / nv.jugadas)}%).`,
      });
    }
  }
  const derrotas = ultimas.filter((r) => r === 'perdida').length;
  if (ultimas.length >= 5 && derrotas >= Math.ceil(ultimas.length * 0.8)) {
    alertas.push({
      nivel: 'media',
      titulo: 'Muchas derrotas seguidas',
      detalle: `${derrotas} de las últimas ${ultimas.length} partidas terminaron en derrota.`,
    });
  }
  if (pagosFallidos > 0) {
    alertas.push({
      nivel: 'media',
      titulo: 'Pagos rechazados por PayPal',
      detalle: `${pagosFallidos} pago(s) no se completaron en las últimas 24 horas.`,
    });
  }
  if (m.usuarios > 0 && m.partidasPorDia.length === 0) {
    alertas.push({
      nivel: 'baja',
      titulo: 'Nadie ha jugado esta semana',
      detalle: 'No hay partidas en los últimos 7 días.',
    });
  }
  return alertas;
}

app.get('/api/metricas', auth, soloAdmin, ah(async (req, res) => {
  res.json(await obtenerMetricas());
}));

// ---------- Asistente de IA del administrador ----------
// El administrador escribe una pregunta. El servidor lee las métricas de MySQL
// en ese momento y se las pasa a Gemini junto con la pregunta, así la respuesta
// siempre usa los datos actuales.
app.post('/api/ia/admin/preguntar', auth, soloAdmin, ah(async (req, res) => {
  const pregunta = String((req.body && req.body.pregunta) || '').trim();
  if (pregunta.length < 2 || pregunta.length > 500) {
    return res.status(400).json({ mensaje: 'Escribe una pregunta de entre 2 y 500 caracteres' });
  }
  if (!iaConfigurada()) {
    return res.status(503).json({ mensaje: 'La IA no está configurada en el servidor (revisa GEMINI_API_KEY en .env)' });
  }
  const metricas = await obtenerMetricas();
  const prompt =
    'Eres el asistente del administrador del juego "Memory Honduras" (un juego de memoria con ' +
    'símbolos patrios y departamentos de Honduras). Abajo tienes las métricas ACTUALES del juego y ' +
    'del servidor Rocky Linux, en formato JSON. Los tiempos están en segundos, la memoria en MB y ' +
    'los montos en lempiras (L).\n\n' +
    'Reglas:\n' +
    '- Responde en español, claro y breve (máximo 120 palabras).\n' +
    '- Usa SOLO los datos del JSON. Si la respuesta no está en los datos, dilo con honestidad.\n' +
    '- Cuando ayude, da números concretos y una recomendación corta.\n' +
    '- No uses formato Markdown (sin asteriscos ni almohadillas).\n\n' +
    `MÉTRICAS:\n${JSON.stringify(metricas)}\n\n` +
    `PREGUNTA DEL ADMINISTRADOR: ${pregunta}`;
  const respuesta = await llamarGemini(prompt, { temperatura: 0.4, maxTokens: 1000 });
  if (!respuesta) {
    return res.status(503).json({ mensaje: 'La IA está ocupada en este momento, intenta de nuevo en unos segundos' });
  }
  res.json({ respuesta, generado: metricas.generado });
}));

// ---------- Consejos de la IA para el jugador ----------
// Al terminar una partida, la app pide un consejo. El servidor lee de MySQL las
// últimas partidas de ESE jugador y Gemini le da un consejo corto y personal.
// Si la IA no responde, se usa un consejo armado con reglas sencillas.
function consejoDeRespaldo(ultima, partidas) {
  if (!ultima) return '¡Juega tu primera partida! Empieza por el Nivel 1 para conocer los símbolos.';
  if (ultima.resultado === 'ganada') {
    const ganadas = partidas.filter((x) => x.resultado === 'ganada').length;
    return ganadas >= 3
      ? '¡Vas muy bien! Intenta el siguiente nivel o gana con menos movidas para subir tu puntaje.'
      : '¡Bien hecho! Para más puntos, termina más rápido: cada segundo que te sobra suma.';
  }
  if (ultima.parejas_encontradas < ultima.num_parejas / 2) {
    return 'Destapa las cartas de una fila a la vez y repite en tu mente lo que viste; así es más fácil recordar.';
  }
  return '¡Te faltó poco! Cuando veas una carta que ya apareció, busca su pareja de inmediato.';
}

app.get('/api/ia/jugador/consejo', auth, ah(async (req, res) => {
  const [partidas] = await pool.execute(
    `SELECT p.id_nivel AS nivel, p.resultado, p.puntaje, p.intentos, p.parejas_encontradas,
            p.duracion_seg, p.modo, n.num_parejas, n.tiempo_limite_seg, n.dificultad
       FROM partidas p JOIN niveles n ON n.id_nivel = p.id_nivel
      WHERE p.id_usuario = ?
      ORDER BY p.id_partida DESC LIMIT 10`,
    [req.user.id]
  );
  const ultima = partidas[0];
  const respaldo = consejoDeRespaldo(ultima, partidas);
  if (!ultima || !iaConfigurada()) return res.json({ consejo: respaldo, ia: false });

  const prompt =
    'Eres el entrenador amigable del juego de memoria "Memory Honduras", para estudiantes. ' +
    'Abajo están las últimas partidas de un jugador (la primera es la que acaba de terminar). ' +
    'Cada partida tiene: nivel, resultado, puntaje, intentos (movidas), parejas encontradas de ' +
    'cuántas había (num_parejas), duración y tiempo límite en segundos.\n' +
    'Dale UN consejo práctico y motivador para mejorar, basado en esos números. ' +
    'Máximo 30 palabras, en español, hablándole de "tú", sin Markdown, sin saludar y sin comillas.\n\n' +
    `PARTIDAS:\n${JSON.stringify(partidas)}`;
  const consejo = await llamarGemini(prompt, { temperatura: 0.8, maxTokens: 400, esperaMs: 10000 });
  res.json(consejo ? { consejo, ia: true } : { consejo: respaldo, ia: false });
}));

// ---------- La app web (Flutter) servida desde Rocky ----------
// Si existe la carpeta app_web (la app compilada con "flutter build web"),
// el servidor la entrega en /juego/. Así, con un solo enlace de ngrok, los
// jugadores abren el juego desde internet sin instalar nada.
const carpetaApp = path.join(__dirname, 'app_web');
const hayAppWeb = () => require('fs').existsSync(path.join(carpetaApp, 'index.html'));
app.use('/juego', express.static(carpetaApp));
app.get('/', (req, res) => res.redirect(hayAppWeb() ? '/juego/' : '/panel'));
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
