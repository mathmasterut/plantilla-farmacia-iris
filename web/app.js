// Farmacia Huasteca · codigo compartido por todas las paginas.
// Cada pagina habla con IRIS SOLO a traves de la funcion api(), que hace
// peticiones HTTP a la API REST (clase Farmacia.API) y recibe JSON.

// Direccion de la API: las paginas las entrega IRIS desde /farmacia,
// asi que la API esta en el mismo servidor, en /farmacia/api.
const API = (() => {
  const desdeURL = new URLSearchParams(location.search).get("api");   // solo para pruebas locales
  if (desdeURL) return desdeURL.replace(/\/+$/, "");
  return location.origin + "/farmacia/api";
})();

// Llama a la API y devuelve el JSON. Si IRIS responde con error, lanza un Error con su mensaje.
async function api(ruta, metodo = "GET", datos) {
  const opciones = { method: metodo, headers: {} };
  if (datos !== undefined) {
    opciones.headers["Content-Type"] = "application/json";
    opciones.body = JSON.stringify(datos);              // el objeto JS viaja como texto JSON
  }
  let r;
  try {
    r = await fetch(API + ruta, opciones);
  } catch (e) {
    throw new Error("Sin conexión con IRIS. Revisa que el codespace esté encendido y el puerto 52773 sea público.");
  }
  const texto = await r.text();
  let json = null;
  try { json = texto ? JSON.parse(texto) : null; } catch (e) { /* respuesta no JSON */ }
  if (!r.ok) throw new Error((json && (json.error || (json.errors && json.errors[0] && json.errors[0].error))) || ("Error HTTP " + r.status));
  return json;
}

// Formatos
const pesos = n => new Intl.NumberFormat("es-MX", { style: "currency", currency: "MXN" }).format(Number(n) || 0);
// IRIS guarda la hora en UTC ("2026-10-14 12:56:59"); aqui se muestra en la hora local.
function fechaLocal(s) {
  if (!s) return "";
  const d = new Date(String(s).replace(" ", "T") + "Z");
  return isNaN(d) ? s : d.toLocaleString("es-MX", { dateStyle: "short", timeStyle: "short" });
}
function fechaCorta(s) {
  if (!s) return "";
  const [a, m, d] = String(s).split("-");
  return d && m && a ? d + "/" + m + "/" + a : s;
}

// Crea elementos sin insertar HTML con datos del usuario.
function el(tag, clase, texto) {
  const e = document.createElement(tag);
  if (clase) e.className = clase;
  if (texto !== undefined && texto !== null) e.textContent = texto;
  return e;
}
function chip(texto, clase) { return el("span", "chip " + (clase || ""), texto); }

// Muestra un mensaje dentro de un contenedor.
function mensaje(contenedor, texto, tipo = "info") {
  contenedor.textContent = "";
  if (!texto) return;
  contenedor.append(el("div", "aviso " + tipo, texto));
}

// Barra superior comun a todas las paginas, con el estado de la conexion.
function barra(actual) {
  const paginas = [["index.html", "Inicio"], ["venta.html", "Punto de venta"], ["inventario.html", "Inventario"], ["reportes.html", "Ventas"], ["catalogo.html", "Catálogo"]];
  const b = el("header", "barra");
  const i = el("div", "barra-int");
  const marca = el("a", "marca"); marca.href = "index.html";
  marca.append(el("span", "cruz"), "Farmacia Huasteca");
  const nav = el("nav", "menu"); nav.setAttribute("aria-label", "Secciones");
  for (const [href, t] of paginas) {
    const a = el("a", null, t); a.href = href;
    if (href === actual) a.setAttribute("aria-current", "page");
    nav.append(a);
  }
  const est = el("span", "estado"); est.append(el("i"), el("span", null, "Conectando…"));
  i.append(marca, nav, est); b.append(i);
  document.body.prepend(b);
  api("/ping").then(d => { est.className = "estado ok"; est.lastChild.textContent = "IRIS · " + d.namespace; })
              .catch(() => { est.className = "estado no"; est.lastChild.textContent = "Sin conexión"; });
}
