/// API REST de la farmacia. La aplicacion web llama a estas rutas con fetch()
/// y cada ruta convierte la peticion en OBJETOS de IRIS (y al reves).
/// Esta clase viene lista en la plantilla: lee los comentarios para ver
/// como una peticion HTTP se convierte en %New(), %OpenId() y %Save().
Class Farmacia.API Extends %CSP.REST
{

/// Respuestas en JSON y UTF-8; el cuerpo de las peticiones se convierte desde UTF-8.
Parameter CONTENTTYPE = "application/json";

Parameter CHARSET = "utf-8";

Parameter CONVERTINPUTSTREAM = 1;

/// Permite llamadas desde otra direccion (CORS), util al probar desde otra pagina.
Parameter HandleCorsRequest = 1;

/// Mapa de rutas: metodo HTTP + direccion -> metodo de esta clase.
XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/ping" Method="GET" Call="Ping"/>
<Route Url="/productos" Method="GET" Call="ListarProductos"/>
<Route Url="/productos" Method="POST" Call="CrearProducto"/>
<Route Url="/productos/:id/surtir" Method="POST" Call="SurtirProducto"/>
<Route Url="/proveedores" Method="GET" Call="ListarProveedores"/>
<Route Url="/proveedores" Method="POST" Call="CrearProveedor"/>
<Route Url="/clientes" Method="GET" Call="ListarClientes"/>
<Route Url="/clientes" Method="POST" Call="CrearCliente"/>
<Route Url="/ventas" Method="GET" Call="ListarVentas"/>
<Route Url="/ventas" Method="POST" Call="CrearVenta"/>
<Route Url="/ventas/:id" Method="GET" Call="VerVenta"/>
<Route Url="/resumen" Method="GET" Call="Resumen"/>
</Routes>
}

// ===================================================== utilidades

/// Lee el cuerpo JSON de la peticion como objeto dinamico.
ClassMethod Cuerpo() As %DynamicObject
{
    if '$isobject(%request.Content) quit {}
    quit {}.%FromJSON(%request.Content)
}

/// Responde un error de validacion (400) con un mensaje claro para la pagina.
ClassMethod Fallo(sc As %Status, codigo As %String = "400 Bad Request") As %Status
{
    set %response.Status = codigo
    set texto = $system.Status.GetErrorText(sc)
    set texto = $piece(texto, "ERROR #5001: ", 2)_$select(texto [ "ERROR #5001: ": "", 1: texto)
    write {"error": (texto)}.%ToJSON()
    quit $$$OK
}

/// Convierte un producto (de cualquier subclase) en JSON. Usa sus metodos polimorficos.
ClassMethod ProductoJSON(p As Farmacia.Producto) As %DynamicObject
{
    set o = {}
    set o.id = p.%Id(), o.codigo = p.Codigo, o.nombre = p.Nombre
    set o.clase = p.%ClassName(1)                      // clase real del objeto
    set o.tipo = p.Tipo()                              // POLIMORFISMO
    set o.precio = +p.Precio, o.tasaIVA = +p.TasaIVA()
    set o.existencia = p.Existencia, o.minimo = p.Minimo, o.bajoMinimo = (p.BajoMinimo() = 1)
    set o.requiereReceta = (p.RequiereReceta() = 1)
    set o.proveedor = $select($isobject(p.Proveedor): p.Proveedor.Nombre, 1: "")
    if p.%IsA("Farmacia.Medicamento") {                // datos que solo tienen los medicamentos
        set o.sustancia = p.SustanciaActiva, o.presentacion = p.Presentacion, o.concentracion = p.Concentracion
        set o.caducidad = $zdate(p.Caducidad, 3), o.caducado = (p.Caducado() = 1)
    }
    if p.%IsA("Farmacia.MedicamentoControlado") set o.grupo = p.Grupo
    quit o
}

/// Convierte una venta en JSON (ticket completo).
ClassMethod VentaJSON(v As Farmacia.Venta) As %DynamicObject
{
    set o = {}
    set o.id = v.%Id(), o.fecha = v.Fecha
    set o.cliente = $select($isobject(v.Cliente): v.Cliente.Nombre, 1: "Publico en general")
    set o.subtotal = +v.Subtotal, o.iva = +v.IVA, o.total = +v.Total
    set o.partidas = []
    for i = 1:1:v.Partidas.Count() {
        set p = v.Partidas.GetAt(i)
        set r = {}
        set r.productoId = p.Producto.%Id(), r.producto = p.Producto.Nombre
        set r.cantidad = p.Cantidad, r.precio = +p.PrecioUnitario, r.tasaIVA = +p.TasaIVA, r.importe = +p.Importe()
        do o.partidas.%Push(r)
    }
    if v.Receta.Medico '= "" {
        set o.receta = {}
        set o.receta.medico = v.Receta.Medico, o.receta.cedula = v.Receta.Cedula, o.receta.fecha = $zdate(v.Receta.Fecha, 3)
    }
    quit o
}

// ===================================================== rutas

/// GET /ping
ClassMethod Ping() As %Status
{
    set o = {}
    set o.ok = 1, o.namespace = $namespace, o.hora = $zdatetime($horolog, 3)
    write o.%ToJSON()
    quit $$$OK
}

/// GET /productos?buscar=texto   Lista productos (los abre como objetos para usar sus metodos).
ClassMethod ListarProductos() As %Status
{
    set buscar = "%"_$zconvert(%request.Get("buscar"), "U")_"%"
    set sql = "SELECT ID FROM Farmacia.Producto WHERE UPPER(Nombre) LIKE ? OR UPPER(Codigo) LIKE ? ORDER BY Nombre"
    set rs = ##class(%SQL.Statement).%ExecDirect(, sql, buscar, buscar)
    set lista = []
    while rs.%Next() {
        set p = ##class(Farmacia.Producto).%OpenId(rs.%Get("ID"))
        if $isobject(p) do lista.%Push(..ProductoJSON(p))
    }
    write lista.%ToJSON()
    quit $$$OK
}

/// POST /productos   Crea un producto de la clase que indique "tipo".
ClassMethod CrearProducto() As %Status
{
    set d = ..Cuerpo()
    set clase = $case(d.tipo, "Medicamento": "Farmacia.Medicamento", "Controlado": "Farmacia.MedicamentoControlado", : "Farmacia.Producto")
    set p = $classmethod(clase, "%New")                // crea un objeto de la clase elegida
    set p.Codigo = d.codigo, p.Nombre = d.nombre, p.Precio = d.precio
    set p.Existencia = +d.existencia
    if d.minimo '= "" set p.Minimo = d.minimo
    if d.proveedorId '= "" set p.Proveedor = ##class(Farmacia.Proveedor).%OpenId(d.proveedorId)
    if p.%IsA("Farmacia.Medicamento") {
        set p.SustanciaActiva = d.sustancia, p.Presentacion = d.presentacion, p.Concentracion = d.concentracion
        set p.Caducidad = $zdateh(d.caducidad, 3, , , , , , , "")
    }
    if p.%IsA("Farmacia.MedicamentoControlado") set p.Grupo = d.grupo
    set sc = p.%Save()                                 // VALIDA y guarda
    if $$$ISERR(sc) quit ..Fallo(sc)
    write ..ProductoJSON(p).%ToJSON()
    quit $$$OK
}

/// POST /productos/:id/surtir   {"cantidad": 10}
ClassMethod SurtirProducto(id As %String) As %Status
{
    set p = ##class(Farmacia.Producto).%OpenId(id)
    if '$isobject(p) quit ..Fallo($$$ERROR($$$GeneralError, "No existe el producto "_id), "404 Not Found")
    set sc = p.Surtir(..Cuerpo().cantidad)
    if $$$ISERR(sc) quit ..Fallo(sc)
    write ..ProductoJSON(p).%ToJSON()
    quit $$$OK
}

/// GET /proveedores
ClassMethod ListarProveedores() As %Status
{
    set lista = []
    set rs = ##class(%SQL.Statement).%ExecDirect(, "SELECT ID, Nombre, Telefono, Email FROM Farmacia.Proveedor ORDER BY Nombre")
    while rs.%Next() {
        set o = {}
        set o.id = rs.%Get("ID"), o.nombre = rs.%Get("Nombre"), o.telefono = rs.%Get("Telefono"), o.email = rs.%Get("Email")
        do lista.%Push(o)
    }
    write lista.%ToJSON()
    quit $$$OK
}

/// POST /proveedores   {"nombre": "...", "telefono": "...", "email": "..."}
ClassMethod CrearProveedor() As %Status
{
    set d = ..Cuerpo()
    set p = ##class(Farmacia.Proveedor).%New()
    set p.Nombre = d.nombre, p.Telefono = d.telefono, p.Email = d.email
    set sc = p.%Save()
    if $$$ISERR(sc) quit ..Fallo(sc)
    write {"id": (p.%Id()), "nombre": (p.Nombre)}.%ToJSON()
    quit $$$OK
}

/// GET /clientes
ClassMethod ListarClientes() As %Status
{
    set lista = []
    set rs = ##class(%SQL.Statement).%ExecDirect(, "SELECT ID, Nombre, Telefono, Puntos FROM Farmacia.Cliente ORDER BY Nombre")
    while rs.%Next() {
        set o = {}
        set o.id = rs.%Get("ID"), o.nombre = rs.%Get("Nombre"), o.telefono = rs.%Get("Telefono"), o.puntos = +rs.%Get("Puntos")
        do lista.%Push(o)
    }
    write lista.%ToJSON()
    quit $$$OK
}

/// POST /clientes   {"nombre": "...", "telefono": "7711234567"}
ClassMethod CrearCliente() As %Status
{
    set d = ..Cuerpo()
    set c = ##class(Farmacia.Cliente).%New()
    set c.Nombre = d.nombre, c.Telefono = d.telefono
    set sc = c.%Save()
    if $$$ISERR(sc) quit ..Fallo(sc)
    write {"id": (c.%Id()), "nombre": (c.Nombre)}.%ToJSON()
    quit $$$OK
}

/// POST /ventas   Registra la venta con la TRANSACCION de Farmacia.Venta.Registrar()
ClassMethod CrearVenta() As %Status
{
    set sc = ##class(Farmacia.Venta).Registrar(..Cuerpo(), .venta)
    if $$$ISERR(sc) quit ..Fallo(sc)
    write ..VentaJSON(venta).%ToJSON()
    quit $$$OK
}

/// GET /ventas   Ultimas 30 ventas.
ClassMethod ListarVentas() As %Status
{
    set lista = []
    set rs = ##class(%SQL.Statement).%ExecDirect(, "SELECT TOP 30 ID, Fecha, Cliente->Nombre AS Cliente, Total FROM Farmacia.Venta ORDER BY ID DESC")
    while rs.%Next() {
        set o = {}
        set o.id = rs.%Get("ID"), o.fecha = rs.%Get("Fecha"), o.total = +rs.%Get("Total")
        set o.cliente = $select(rs.%Get("Cliente") = "": "Publico en general", 1: rs.%Get("Cliente"))
        do lista.%Push(o)
    }
    write lista.%ToJSON()
    quit $$$OK
}

/// GET /ventas/:id   Ticket completo de una venta.
ClassMethod VerVenta(id As %String) As %Status
{
    set v = ##class(Farmacia.Venta).%OpenId(id)
    if '$isobject(v) quit ..Fallo($$$ERROR($$$GeneralError, "No existe la venta "_id), "404 Not Found")
    write ..VentaJSON(v).%ToJSON()
    quit $$$OK
}

/// GET /resumen   Numeros para el tablero (consultas SQL sobre los objetos).
ClassMethod Resumen() As %Status
{
    set o = {}
    set hoy = $zdate(+$horolog, 3)
    set rs = ##class(%SQL.Statement).%ExecDirect(, "SELECT COUNT(*) AS N, SUM(Total) AS T FROM Farmacia.Venta WHERE Fecha >= ?", hoy)
    do rs.%Next()
    set o.ventasHoy = +rs.%Get("N"), o.totalHoy = +rs.%Get("T")
    set rs = ##class(%SQL.Statement).%ExecDirect(, "SELECT COUNT(*) AS N FROM Farmacia.Producto")
    do rs.%Next()
    set o.productos = +rs.%Get("N")
    set rs = ##class(%SQL.Statement).%ExecDirect(, "SELECT COUNT(*) AS N FROM Farmacia.Producto WHERE Existencia <= Minimo")
    do rs.%Next()
    set o.bajoMinimo = +rs.%Get("N")
    set rs = ##class(%SQL.Statement).%ExecDirect(, "SELECT COUNT(*) AS N FROM Farmacia.Medicamento WHERE Caducidad < ?", +$horolog)
    do rs.%Next()
    set o.caducados = +rs.%Get("N")
    write o.%ToJSON()
    quit $$$OK
}

}
