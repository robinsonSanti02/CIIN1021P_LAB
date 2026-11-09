db = db.getSiblingDB("DataSaludNoSQLTema04");

db.detalleAtenciones.createIndex({ atencionId: 1 }, { unique: true });

if (db.detalleAtenciones.countDocuments({ atencionId: 1101 }) === 0) {
    db.detalleAtenciones.insertOne({
        atencionId: 1101,
        tipo: "CONSULTA",
        fecha: new Date("2026-10-01T00:00:00Z"),
        estado: "PENDIENTE",
        datos: { canal: "PRESENCIAL", minutosEspera: 20 },
        etiquetas: ["CONSULTA", "PRESENCIAL"]
    });
}

print("Nombre de la base:", db.getName());
print("Documento 1101:");
printjson(db.detalleAtenciones.findOne({ atencionId: 1101 }));
print("Coincidencias 1101:", db.detalleAtenciones.countDocuments({ atencionId: 1101 }));
print("Indice de negocio:");
printjson(db.detalleAtenciones.getIndexes().filter(x => x.name === "atencionId_1"));
