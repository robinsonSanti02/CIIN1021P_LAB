db = db.getSiblingDB("DataSaludNoSQLTema04");
db.atencionesImportadas.createIndex({ atencionId: 1 }, { unique: true });

var loteSQL = [
    { atencionId: 1101, establecimientoId: 1, fecha: "2026-10-01", tipo: "CONSULTA", duracionMinutos: 20, origen: "SQL_E04" },
    { atencionId: 1102, establecimientoId: 2, fecha: "2026-10-02", tipo: "CONTROL", duracionMinutos: 15, origen: "SQL_E04" },
    { atencionId: 1103, establecimientoId: 1, fecha: "2026-10-03", tipo: "VACUNACION", duracionMinutos: 10, origen: "SQL_E04" }
];

if (loteSQL.length !== 3 || loteSQL.some(x => ![1101, 1102, 1103].includes(x.atencionId))) {
    throw new Error("Revisa el JSON: se esperan las atenciones 1101, 1102 y 1103.");
}

loteSQL.forEach(function(fila) {
    db.atencionesImportadas.updateOne(
        { atencionId: fila.atencionId },
        { $set: fila },
        { upsert: true }
    );
});

print("E04-T2 cantidad de SQL_E04:", db.atencionesImportadas.countDocuments({ origen: "SQL_E04" }));
printjson(db.atencionesImportadas.find({ origen: "SQL_E04" }, { _id: 0 }).sort({ atencionId: 1 }).toArray());

print("Agregar atributo local 1102:");
printjson(db.atencionesImportadas.updateOne(
    { atencionId: 1102 },
    { $set: { "metadatos.canal": "VIRTUAL" } }
));

loteSQL.forEach(function(fila) {
    db.atencionesImportadas.updateOne(
        { atencionId: fila.atencionId },
        { $set: fila },
        { upsert: true }
    );
});

print("1102 tras repetir el lote:");
printjson(db.atencionesImportadas.findOne({ atencionId: 1102 }, { projection: { _id: 0 } }));
print("Documentos importados:", db.atencionesImportadas.countDocuments({ origen: "SQL_E04" }));
print("Atencion 1104 importada:", db.atencionesImportadas.countDocuments({ atencionId: 1104 }));
