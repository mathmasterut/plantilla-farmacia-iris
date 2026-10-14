/// Utilerias: carga un catalogo de ejemplo y borra los datos.
/// Viene lista en la plantilla. Los productos son ficticios.
Class Farmacia.Datos
{

/// Borra todos los objetos de la farmacia y reinicia los IDs.
ClassMethod Limpiar() As %Status
{
    do ##class(Farmacia.Venta).%KillExtent()
    do ##class(Farmacia.Producto).%KillExtent()       // tambien medicamentos y controlados
    do ##class(Farmacia.Proveedor).%KillExtent()
    do ##class(Farmacia.Cliente).%KillExtent()
    write "Farmacia vacia: datos borrados.", !
    quit $$$OK
}

/// Crea 3 proveedores, 2 clientes y 12 productos de ejemplo.
ClassMethod Cargar() As %Status
{
    set sc = $$$OK
    try {
        do ..Limpiar()
        set lab = ..Proveedor("Laboratorios Sierra Madre", "7711002030", "pedidos@sierramadre.example")
        set dis = ..Proveedor("Distribuidora del Golfo", "7898004050", "ventas@delgolfo.example")
        set hig = ..Proveedor("Higiene Total", "5550012233", "contacto@higienetotal.example")
        set hoy = +$horolog

        // ---- Productos generales (IVA 16 %) ----
        do ..General("7501000000011", "Cubrebocas tricapa 10 piezas", 45, 40, hig)
        do ..General("7501000000028", "Gel antibacterial 250 ml", 38.5, 25, hig)
        do ..General("7501000000035", "Termometro digital", 129, 6, dis)

        // ---- Medicamentos (IVA 0 %) ----
        do ..Medicamento("7502000000017", "Paracetamol 500 mg 10 tabletas", 32, 60, lab, "Paracetamol", "Tabletas", "500 mg", hoy + 400)
        do ..Medicamento("7502000000024", "Ibuprofeno 400 mg 10 tabletas", 48, 35, lab, "Ibuprofeno", "Tabletas", "400 mg", hoy + 300)
        do ..Medicamento("7502000000031", "Loratadina 10 mg 20 tabletas", 65, 18, dis, "Loratadina", "Tabletas", "10 mg", hoy + 500)
        do ..Medicamento("7502000000048", "Omeprazol 20 mg 14 capsulas", 89, 4, dis, "Omeprazol", "Capsulas", "20 mg", hoy + 250)
        do ..Medicamento("7502000000055", "Paracetamol infantil 120 ml", 54, 12, lab, "Paracetamol", "Suspension", "160 mg/5 ml", hoy + 180)
        do ..Medicamento("7502000000062", "Ambroxol jarabe 120 ml", 72, 9, lab, "Ambroxol", "Jarabe", "30 mg/5 ml", hoy - 20)   // CADUCADO a proposito

        // ---- Medicamentos controlados (requieren receta) ----
        do ..Controlado("7503000000013", "Amoxicilina 500 mg 12 capsulas", 110, 15, lab, "Amoxicilina", "Capsulas", "500 mg", hoy + 365, "Antibiotico")
        do ..Controlado("7503000000020", "Azitromicina 500 mg 3 tabletas", 175, 8, dis, "Azitromicina", "Tabletas", "500 mg", hoy + 300, "Antibiotico")
        do ..Controlado("7503000000037", "Clonazepam 2 mg 30 tabletas", 210, 3, lab, "Clonazepam", "Tabletas", "2 mg", hoy + 420, "Psicotropico")

        // ---- Clientes ----
        for nombre = "Rosa Hernandez Cruz", "Miguel Angel Bautista" {
            set c = ##class(Farmacia.Cliente).%New()
            set c.Nombre = nombre, c.Telefono = $select(nombre [ "Rosa": "7711234567", 1: "7719876543")
            $$$ThrowOnError(c.%Save())
        }
        write "Catalogo cargado: 3 proveedores, 12 productos y 2 clientes.", !
    } catch ex {
        set sc = ex.AsStatus()
        do $system.Status.DisplayError(sc)
    }
    quit sc
}

ClassMethod Proveedor(nombre As %String, tel As %String, email As %String) As Farmacia.Proveedor
{
    set p = ##class(Farmacia.Proveedor).%New()
    set p.Nombre = nombre, p.Telefono = tel, p.Email = email
    $$$ThrowOnError(p.%Save())
    quit p
}

ClassMethod General(codigo, nombre, precio, existencia, prov As Farmacia.Proveedor) As Farmacia.Producto
{
    set p = ##class(Farmacia.Producto).%New()
    set p.Codigo = codigo, p.Nombre = nombre, p.Precio = precio, p.Existencia = existencia, p.Proveedor = prov
    $$$ThrowOnError(p.%Save())
    quit p
}

ClassMethod Medicamento(codigo, nombre, precio, existencia, prov, sustancia, presentacion, concentracion, caducidad) As Farmacia.Medicamento
{
    set m = ##class(Farmacia.Medicamento).%New()
    do ..LlenarMedicamento(m, codigo, nombre, precio, existencia, prov, sustancia, presentacion, concentracion, caducidad)
    $$$ThrowOnError(m.%Save())
    quit m
}

ClassMethod Controlado(codigo, nombre, precio, existencia, prov, sustancia, presentacion, concentracion, caducidad, grupo) As Farmacia.MedicamentoControlado
{
    set m = ##class(Farmacia.MedicamentoControlado).%New()
    do ..LlenarMedicamento(m, codigo, nombre, precio, existencia, prov, sustancia, presentacion, concentracion, caducidad)
    set m.Grupo = grupo
    $$$ThrowOnError(m.%Save())
    quit m
}

ClassMethod LlenarMedicamento(m, codigo, nombre, precio, existencia, prov, sustancia, presentacion, concentracion, caducidad)
{
    set m.Codigo = codigo, m.Nombre = nombre, m.Precio = precio, m.Existencia = existencia, m.Proveedor = prov
    set m.SustanciaActiva = sustancia, m.Presentacion = presentacion, m.Concentracion = concentracion, m.Caducidad = caducidad
}

}
