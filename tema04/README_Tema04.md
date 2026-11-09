# Tema 04 - Nuevos paradigmas en el manejo de datos

**Curso:** Base de Datos Avanzadas y Big Data (CIIN1021P)  
**Universidad:** Universidad Privada del Norte (UPN)  
**Caso:** DataSalud Peru - datos sinteticos  
**Docente:** Ing. Andres E. Araujo Acuna  
**Alumno:** Robinson Jair Santisteban Llaguento  
**Fecha de practica:** 9 de noviembre de 2026

## Contenido

| Archivo | Proposito | Entorno |
|---|---|---|
| `00_Preparacion_DataSalud_T04.sql` | Preparacion original entregada por el docente, sin modificar | SSMS |
| `Tema4_Ejercicio01.sql` | Consulta critica; medicion antes y despues del indice | SSMS |
| `Tema4_Ejercicio02.mongosh.js` | Documento 1101 e indice unico | mongosh |
| `Tema4_Ejercicio03.mongosh.js` | CRUD, proyeccion, prueba de repeticion y eliminacion | mongosh |
| `Tema4_Ejercicio04_SQL.sql` | Exportacion del lote T04_DEMO con `FOR JSON PATH` | SSMS |
| `E04_Lote_SQL_E04.json` | Instantanea del JSON observado durante la practica | Datos |
| `Tema4_Ejercicio04_MongoDB.mongosh.js` | Importacion manual repetible y conservacion de metadatos | mongosh |
| `Tema4_Ejercicio05.mongosh.js` | Codigo propio de consulta, actualizacion, eliminacion y `$all` | mongosh |
| `Tema4_Verificacion_SQL.sql` | Comprobacion de los identificadores 1105 a 1108 en SQL Server | SSMS |
| `Informe_Tema04_Santisteban.pdf` | Informe academico con mediciones, tablas y capturas | PDF |
| `evidencias/` | Capturas originales de SSMS, mongosh y Compass | PNG |

## Ejecucion y cuidados

1. El script del docente prepara **BDDataSaludTema04**, independiente de los temas previos. Ya fue ejecutado en la sesion. No lo repitas para intentar recuperar datos modificados; no sobrescribe necesariamente cambios.
2. **No ejecutes todos los archivos sobre el entorno ya terminado solo para probarlos.** Los scripts conservan la secuencia de la practica y algunas operaciones cambian datos. Son un registro reproducible sobre un entorno de laboratorio preparado, no un instalador de produccion.
3. El Ejercicio 01 elimina **solo** el indice experimental `IX_T04_Atencion_Establecimiento_Fecha` si existe, lo vuelve a crear y compara las dos ejecuciones. Conserva las capturas con la medicion del equipo original.
4. En mongosh se usa `db = db.getSiblingDB("DataSaludNoSQLTema04")`. Los archivos `.mongosh.js` son JavaScript para MongoDB Shell, **no** son T-SQL ni scripts de navegador.
5. Los Ejercicios 02, 03 y 05 incluyen verificaciones para evitar duplicar lotes al ejecutar de nuevo una coleccion parcialmente trabajada; repetir la ejecucion puede devolver `modifiedCount: 0` y `deletedCount: 0`, porque esas operaciones ya ocurrieron.
6. `E04_Lote_SQL_E04.json` es una **instantanea manual**, no una conexion en vivo. Si cambia la fuente SQL, regenera y compara el JSON antes de importar; el script MongoDB conserva la muestra validada de 1101 a 1103.
7. El documento `1199` se elimina solo en MongoDB, **nunca** del SQL de origen.
8. Antes de publicar, verifica que ninguna captura incluya contrasenas o datos reales. Los registros de la guia son sinteticos.

## Mediciones observadas

| Prueba | Antes | Despues |
|---|---:|---:|
| Consulta E01: filas | 822 | 822 |
| Consulta E01: lecturas logicas en `Atencion` | 339 | 5 |
| Consulta E01: operador | Sin captura concluyente | `Index Seek (NonClustered)` |

Reduccion de lecturas logicas: **98,53 %** = (339 - 5) / 339 x 100. El intento duplicado de `CREATE INDEX` en la sesion genero el error 1913 porque el indice ya existia; la consulta de lectura posterior finalizo y fue medida correctamente.

### MongoDB

- E02: documento 1101 en Compass con `datos` y `etiquetas` expandidos.
- E03: cinco documentos iniciales, filtro CONTROL/espera > 30 obtiene 1102; primera actualizacion `matchedCount=1`, `modifiedCount=1`, repeticion `modifiedCount=0`, ID 9999 `matchedCount=0`; borrado 1199 deja cuatro documentos.
- E04: tres documentos transferidos (1101, 1102, 1103), el 1104 OBSERVADO excluido. Tras reimportar, 1102 conserva `metadatos.canal=VIRTUAL`.
- E05: cinco documentos de prueba inicialmente; consulta virtual devuelve 1105; 1106 conserva canal y espera tras `$set`; se elimina 1199; `$all` devuelve 1105; cuatro identificadores 1105-1108 coinciden con SQL en identificador y tipo.

## Decisiones de arquitectura

- **SQL Server** conserva identificadores, establecimiento, estado de origen y reglas de seleccion del lote.
- **MongoDB** registra atributos adicionales flexibles (objetos y arreglos) y un estado de revision documental independiente de `EstadoRegistro`.
- **Importacion** manual mediante `FOR JSON PATH`, `updateOne` y `upsert: true`: evita duplicados por indice unico pero **no** implementa sincronizacion automatica, clave foranea entre motores, replicacion ni particionamiento.
- **Replicacion** responde a disponibilidad y continuidad; **particionamiento** responde a volumen/carga medidos. Sin mediciones ni necesidad, no distribuir por defecto.

## Fuentes

- UPN (2026), *JP_BD_GUIA_ACTIVIDADES_S4-v3.docx*, material del curso.
- Microsoft Learn, *Format Query Results as JSON with FOR JSON*: https://learn.microsoft.com/en-us/sql/relational-databases/json/format-query-results-as-json-with-for-json-sql-server
- MongoDB Manual, *CRUD Operations*: https://www.mongodb.com/docs/manual/crud/
- MongoDB Manual, *$set*: https://www.mongodb.com/docs/manual/reference/operator/update/set/
- MongoDB Manual, *$all*: https://www.mongodb.com/docs/manual/reference/operator/query/all/

**Nota sobre autoria:** los ejercicios fueron ejecutados y documentados con orientacion paso a paso. No se atribuye la resolucion sin ayuda de un ejercicio sin evidencia de ello.
