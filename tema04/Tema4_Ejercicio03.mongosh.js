db = db.getSiblingDB("DataSaludNoSQLTema04");
db.detalleAtenciones.createIndex({ atencionId: 1 }, { unique: true });

var registrosE03 = [
    {
        atencionId: 1102, tipo: "CONTROL", estado: "PENDIENTE",
        fecha: new Date("2026-10-02T00:00:00Z"),
        datos: { canal: "VIRTUAL", minutosEspera: 35 },
        etiquetas: ["SEGUIMIENTO", "REMOTO"]
    },
    {
        atencionId: 1103, tipo: "VACUNACION", estado: "PENDIENTE",
        fecha: new Date("2026-10-03T00:00:00Z"),
        datos: { dosis: 2, vacuna: "SIM-V" },
        etiquetas: ["PREVENCION", "VACUNACION"]
    },
    {
        atencionId: 1104, tipo: "LABORATORIO", estado: "PENDIENTE",
        fecha: new Date("2026-10-04T00:00:00Z"),
        datos: { prueba: "SIM-GLU", valor: 95, unidad: "mg/dL" },
        etiquetas: ["LABORATORIO"]
    },
    {
        atencionId: 1199, tipo: "CONSULTA", estado: "PRUEBA",
        fecha: new Date("2026-10-09T00:00:00Z"),
        datos: { canal: "PRUEBA" },
        etiquetas: ["PRUEBA"]
    }
];

var registrosExistentes = db.detalleAtenciones.countDocuments({
    atencionId: { $in: [1102, 1103, 1104, 1199] }
});

if (registrosExistentes === 0) {
    printjson(db.detalleAtenciones.insertMany(registrosE03));
} else {
    print("Se omite insertMany: ya hay registros del Ejercicio 03.");
}

print("Total de documentos:", db.detalleAtenciones.countDocuments({}));
print("Espera mayor que 30:");
printjson(db.detalleAtenciones.find({
    "datos.minutosEspera": { $gt: 30 }
}).toArray());
print("Con etiqueta REMOTO:");
printjson(db.detalleAtenciones.find({ etiquetas: "REMOTO" }).toArray());
print("E03-T1:");
printjson(db.detalleAtenciones.find(
    { tipo: "CONTROL", "datos.minutosEspera": { $gt: 30 } },
    { _id: 0, atencionId: 1, tipo: 1 }
).toArray());

var filtroRevisar = { atencionId: 1102 };
var cambiosRevisar = {
    $set: { estado: "REVISADA", "datos.revisionRequerida": true }
};
print("E03-T2 primera actualizacion:");
printjson(db.detalleAtenciones.updateOne(filtroRevisar, cambiosRevisar));
print("E03-T2 misma actualizacion repetida:");
printjson(db.detalleAtenciones.updateOne(filtroRevisar, cambiosRevisar));
print("E03-T2 identificador inexistente:");
printjson(db.detalleAtenciones.updateOne({ atencionId: 9999 }, cambiosRevisar));

print("E03-T3 eliminacion especifica:");
printjson(db.detalleAtenciones.deleteOne({ atencionId: 1199, estado: "PRUEBA" }));
print("Atencion 1102 final:");
printjson(db.detalleAtenciones.findOne({ atencionId: 1102 }));
print("Conteo 1101-1104:", db.detalleAtenciones.countDocuments({
    atencionId: { $in: [1101, 1102, 1103, 1104] }
}));
print("Conteo 1199:", db.detalleAtenciones.countDocuments({ atencionId: 1199 }));
