# Comandos de la practica · Farmacia Huasteca

Escribe una linea a la vez y presiona Enter. Lo que va despues de `;` es comentario.

## 1. Entrar al namespace

```
iris session IRIS -U FARMACIA
```

## 2. Compilar tus clases (cada vez que crees o cambies una)

```
set ruta = "PEGA_LA_RUTA_DE_src/Farmacia"     ; clic derecho en la carpeta → Copiar ruta de acceso
do $system.OBJ.LoadDir(ruta, "ck")             ; carga y compila las clases del modelo
```

## 3. Compilar la API y cargar el catalogo (cuando el modelo este completo)

```
set rutaApi = "PEGA_LA_RUTA_DE_src/api"
do $system.OBJ.LoadDir(rutaApi, "ck")          ; compila Farmacia.API y Farmacia.Datos
do ##class(Farmacia.Datos).Cargar()            ; 3 proveedores, 12 productos y 2 clientes
```

## 4. Publicar la aplicacion web (en %SYS)

```
zn "%SYS"
write ^%SYS("CSP","DefaultFileCharset")        ; debe decir utf-8 (si no: set ^%SYS("CSP","DefaultFileCharset") = "utf-8")
kill p  set p("NameSpace") = "FARMACIA", p("DispatchClass") = "Farmacia.API", p("AutheEnabled") = 64, p("MatchRoles") = ":%All", p("Enabled") = 1
write ##class(Security.Applications).Create("/farmacia/api", .p)
kill p  set p("NameSpace") = "FARMACIA", p("Path") = "PEGA_LA_RUTA_DE_web", p("ServeFiles") = 1, p("AutheEnabled") = 64, p("MatchRoles") = ":%All", p("Enabled") = 1
write ##class(Security.Applications).Create("/farmacia", .p)
```

## 5. Cambiar las contrasenas (antes de hacer publico el puerto)

```
set q("Password") = "TuClaveSegura2026"
write ##class(Security.Users).Modify("_SYSTEM", .q)
write ##class(Security.Users).Modify("Admin", .q)
write ##class(Security.Users).Modify("SuperUser", .q)
```

## 6. Abrir la aplicacion

Puertos → 52773 → clic derecho → Port Visibility → **Public**. Abre la direccion del puerto y agrega `/farmacia/index.html`.

## 7. Consultas SQL (Portal → Sistema → SQL, namespace FARMACIA)

```
SELECT ID, Codigo, Nombre, Existencia, x__classname FROM Farmacia.Producto
SELECT ID, Fecha, Cliente->Nombre, Subtotal, IVA, Total, Receta_Medico FROM Farmacia.Venta
SELECT Nombre, Precio, Caducidad FROM Farmacia.Medicamento WHERE Caducidad < CURRENT_DATE
```

## 8. Reiniciar los datos

```
zn "FARMACIA"
do ##class(Farmacia.Datos).Cargar()
```
