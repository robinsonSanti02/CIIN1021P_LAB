db = db.getSiblingDB("DataSaludNoSQLTema04");
db.aplicacionAtenciones.createIndex({ atencionId: 1 }, { unique: true });

var registrosE05 = [
    { atencionId: 1105, tipo: "CONSULTA", estado: "PENDIENTE", datos: { canal: "VIRTUAL", minutosEspera: 35 }, etiquetas: ["REMOTO", "CONTROL"] },
    { atencionId: 1106, tipo: "CONTROL", estado: "PENDIENTE", datos: { canal: "PRESENCIAL", minutosEspera: 12 }, etiquetas: ["SEGUIMIENTO"] },
    { atencionId: 1107, tipo: "VACUNACION", estado: "PENDIENTE", datos: { dosis: 2, vacuna: "SIM-V" }, etiquetas: ["PREVENCION"] },
    { atencionId: 1108, tipo: "LABORATORIO", estado: "PENDIENTE", datos: { prueba: "SIM-GLU", valor: 95, unidad: "mg/dL" }, etiquetas: ["LABORATORIO"] },
    { atencionId: 1199, tipo: "CONSULTA", estado: "PRUEBA", datos: { canal: "PRUEBA" }, etiquetas: ["PRUEBA"] }
];

if (db.aplicacionAtenciones.countDocuments({}) === 0) {
    printjson(db.aplicacionAtenciones.insertMany(registrosE05));
} else {
    print("Se omite insertMany porque la coleccion ya contiene datos.");
}

print("Consulta canal VIRTUAL y espera mayor que 30:");
printjson(db.aplicacionAtenciones.find(
    { "datos.canal": "VIRTUAL", "datos.minutosEspera": { $gt: 30 } },
    { _id: 0, atencionId: 1, tipo: 1, "datos.minutosEspera": 1 }
).toArray());

print("Actualizacion unica de la atencion 1106:");
printjson(db.aplicacionAtenciones.updateOne(
    { atencionId: 1106 },
    { $set: { "datos.revisionRequerida": true } }
));
printjson(db.aplicacionAtenciones.findOne({ atencionId: 1106 }, { projection: { _id: 0 } }));

print("Eliminar exclusivamente documento 1199 en PRUEBA:");
printjson(db.aplicacionAtenciones.deleteOne({ atencionId: 1199, estado: "PRUEBA" }));

print("Consulta con ambas etiquetas REMOTO y CONTROL:");
printjson(db.aplicacionAtenciones.find(
    { etiquetas: { $all: ["REMOTO", "CONTROL"] } },
    { _id: 0, atencionId: 1, tipo: 1, etiquetas: 1 }
).toArray());

print("Estado final en MongoDB:");
printjson(db.aplicacionAtenciones.find(
    {}, { _id: 0, atencionId: 1, tipo: 1 }
).sort({ atencionId: 1 }).toArray());
print("Total final:", db.aplicacionAtenciones.countDocuments({}));
print("1199 restante:", db.aplicacionAtenciones.countDocuments({ atencionId: 1199 }));
