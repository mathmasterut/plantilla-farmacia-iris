# Farmacia Huasteca · Base de datos orientada a objetos con aplicacion web

Practica de bases de datos **NoSQL orientadas a objetos** con **InterSystems IRIS Community Edition** en **GitHub Codespaces**.

Tu construyes la base de datos, el namespace y las **clases del modelo** (paquete `Farmacia`).
La plantilla ya trae la **aplicacion web** (`web/`) y la **API REST** (`src/api/`) que guardan los datos en tus clases.

## Contenido

| Carpeta / archivo | Para que sirve |
|---|---|
| `.devcontainer/`, `Dockerfile`, `docker-compose.yml`, `iris.script` | Levantan IRIS en la nube. No se modifican. |
| `src/api/API.cls` | API REST: convierte las peticiones de la pagina en objetos (`%New`, `%OpenId`, `%Save`). |
| `src/api/Datos.cls` | Carga un catalogo de ejemplo (`Cargar()`) y borra los datos (`Limpiar()`). |
| `src/Farmacia/` | **La creas tu**: las 8 clases del modelo. |
| `web/` | Paginas de la farmacia: inicio, punto de venta, inventario, ventas y catalogo para celular. |
| `COMANDOS.md` | Todos los comandos de la practica, en orden. |

## Modelo (paquete `Farmacia`)

```
Proveedor 1 ──< muchos Producto          (relacion)
Producto (persistente)  General: IVA 16 %
 └── Medicamento        IVA 0 %, sustancia, presentacion, caducidad
      └── MedicamentoControlado   requiere receta
Cliente (persistente)
Venta (persistente) ── Cliente (referencia)
 ├── Partidas: lista de Partida (embebido) ── Producto (referencia)
 └── Receta (embebido)
```

## Accesos

| Que | Dato |
|---|---|
| Terminal de IRIS | `iris session IRIS -U FARMACIA` |
| Portal de administracion | puerto **52773** → `/csp/sys/UtilHome.csp` |
| Aplicacion web | puerto **52773** (publico) → `/farmacia/index.html` |
| Usuario inicial | `_SYSTEM` / `SYS` (**cambiala** antes de hacer publico el puerto) |

> Al terminar: pon el puerto en **Private** y deten el codespace (**github.com/codespaces → … → Stop codespace**).
> Usa solo datos ficticios.
