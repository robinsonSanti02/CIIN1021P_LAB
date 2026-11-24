# CIIN1021P_LAB — Laboratorios de los Temas 01 al 05

**Universidad:** Universidad Privada del Norte  
**Carrera:** Ingeniería de Sistemas Computacionales  
**Curso:** Base de Datos Avanzadas y Big Data  
**Docente:** Ing. Andrés E. Araujo Acuña  
**Autor:** SANTISTEBAN LLAGUENTO ROBINSON JAIR  
**Caso de estudio:** DataSalud Perú

## Propósito y alcance

Desarrollar soluciones de bases de datos avanzadas mediante
programación T-SQL, automatización, seguridad, optimización,
bases de datos NoSQL, almacenamiento dimensional y procesos ETL.

Los laboratorios se desarrollan sobre el caso académico
DataSalud Perú, utilizando datos sintéticos.

## Organización del repositorio

| Tema | Contenido | Documentación |
|---|---|---|
| 01 | Programación avanzada en T-SQL | [Tema 01](tema01/) |
| 02 | Automatización y control transaccional | [Tema 02](tema02/README.md) |
| 03 | Seguridad, optimización y respaldo | [Tema 03](tema03/README_Tema03.md) |
| 04 | Nuevos paradigmas en el manejo de datos | [Tema 04](tema04/README_Tema04.md) |
| 05 | Almacén de datos y procesos ETL | [Tema 05](tema05/README_Tema05.md) |

## Herramientas utilizadas

- Microsoft SQL Server.
- SQL Server Management Studio (SSMS).
- MongoDB Community Server.
- MongoDB Compass.
- MongoDB Shell (mongosh).
- Visual Studio 2022.
- SQL Server Integration Services (SSIS).
- Git y GitHub.

## Entorno y orden de ejecución del Tema 01

Se requiere SQL Server 2016 SP1 o posterior y SQL Server Management Studio (SSMS), según la guía del curso.

1. Abrir los archivos SQL en SSMS y conectarse a la instancia de práctica.
2. Ejecutar `Tema1_Ejercicio01.sql` una sola vez para preparar la base.
3. Ejecutar `Tema1_Ejercicio02.sql` y, después, `Tema1_Ejercicio03.sql`.
4. Para reproducir la evaluación de calidad y la ampliación, continuar con los ejercicios 04, 05 y 06, en ese orden.

**Preparación de la base:** el script 01 elimina y vuelve a crear `BDDataSaludTema01`. Debe utilizarse únicamente en el entorno de práctica, conservando antes cualquier trabajo necesario. No se debe repetir entre ejercicios.

Las tres llamadas válidas del ejercicio 03 insertan una atención cada una; repetirlas añade registros. El ejercicio 04 vuelve a crear `AtencionStaging`, por lo que debe ejecutarse antes del 05. Estas dependencias son necesarias para reproducir los conteos de referencia.

## Resultados de referencia del Tema 01

| Ejercicio | Comprobación |
|---|---|
| 01 | Seis grupos de validación: nueve entradas porque el caso 6 contiene cuatro límites. El WHILE recorre 10, 20, 30 y 40 minutos. |
| 02 | Casos 1–6: CORTA, CORTA, REGULAR, REGULAR, PROLONGADA y NULL; además, reutilización sobre siete duraciones. |
| 03 | Tres atenciones válidas. Los cinco casos inválidos producen los errores 50033, 50032, 50036, 50038 y 50039. |
| 04 | LOTE-001: un registro válido, uno observado y cuatro inválidos. |
| 05 | Un registro apto en LOTE-001 y dos en LOTE-002. |
| 06 | Un paciente marcado como inactivo (PAC-004); PAC-005 permanece activo por no tener atenciones. El reporte reciente devuelve una atención por tipo y promedios de 20, 12 y 45 minutos. |

La consulta del ejercicio 03 muestra tres atenciones antes de ejecutar el 06. Este último añade una atención antigua para PAC-004; con ello, el total de la tabla pasa a cuatro, aunque el reporte de los últimos siete días sigue considerando las tres recientes si se ejecuta en la misma sesión de práctica.

Las capturas del PDF documentan la ejecución original del estudiante. La actualización de la documentación conserva los seis scripts del repositorio; no representa una nueva ejecución de SQL Server ni una prueba de rendimiento masivo.

## Criterios éticos y de calidad

- Las reglas se aplican antes del registro y los mensajes de error evitan datos personales innecesarios.
- Una atención de 240 minutos se conserva como `OBSERVADO` y se deriva a revisión; no se elimina para modificar un indicador.
- El plazo de 24 meses es un supuesto del ejercicio, no un plazo legal de conservación de historias clínicas.
- Las fuentes periodísticas y los artículos del Código de Ética del CIP se identifican en el archivo de ética y en las referencias del informe.

## Tema 02

La carpeta [tema02/](tema02/README.md) contiene los cinco ejercicios de automatización y control transaccional, el informe y una consulta complementaria de auditoría. Su README especifica los requisitos, el orden de ejecución y la limpieza previa para repetir el cursor.

- [Informe del Tema 02](tema02/Informe_Tema02_Santisteban.pdf).
- [Instrucciones y resultados esperados](tema02/README.md).

El Tema 02 continúa sobre `BDDataSaludTema01`; no debe reiniciarse la base entre ejercicios. El reto avanzado y la medición de tiempos son opcionales. Los scripts del Tema 02 conservan las explicaciones fuera del código.


## Tema 03 — Seguridad, optimización y respaldo

- Gestión de transacciones.
- Usuarios, roles y permisos.
- Protección de datos sensibles.
- Auditoría de accesos.
- Índices y planes de ejecución.
- Respaldo y restauración de bases de datos.

[Ver laboratorio del Tema 03](tema03/README_Tema03.md)

## Tema 04 — Nuevos paradigmas en el manejo de datos

- Comparación entre SQL Server y MongoDB.
- Consultas optimizadas mediante índices.
- Operaciones CRUD sobre documentos.
- Intercambio de información mediante JSON.
- Arquitectura híbrida relacional y documental.

### Resultados obtenidos

| Indicador | Resultado |
|---|---:|
| Filas consultadas | 822 |
| Lecturas lógicas iniciales | 339 |
| Lecturas lógicas optimizadas | 5 |
| Reducción de lecturas | 98,53 % |
| Documentos importados | 3 |

[Documentación del Tema 04](tema04/README_Tema04.md)

[Informe del Tema 04](tema04/Informe_Tema04_Santisteban.pdf)

## Tema 05 — Almacén de datos y procesos ETL

Implementación de un Data Warehouse para la DIRESA
La Libertad, integrando las fuentes NUCLEO, HIS y CAMPANIA.

### Ejercicios desarrollados

| Ejercicio | Contenido |
|---|---|
| 01 | Del registro al indicador |
| 02 | Modelo dimensional de atenciones |
| 03 | Extracción y transformación mediante SSIS |
| 04 | Carga incremental y control transaccional |
| 05 | Etapa de vida y protección de datos |
| 06 | Vacunación con dimensiones compartidas |

### Resultados obtenidos

| Indicador | Resultado |
|---|---:|
| Atenciones válidas | 12 |
| Minutos acumulados | 190 |
| Registros de vacunación de origen | 8 |
| Dosis únicas almacenadas | 7 |
| Inserciones en la primera carga | 7 |
| Inserciones en la segunda carga | 0 |
| Duplicados en el Data Warehouse | 0 |

### Cobertura de vacunación

| Provincia | Cobertura |
|---|---:|
| Chepén | 50 % |
| Sánchez Carrión | 25 % |
| Trujillo | 50 % |

### Archivos y documentación

- [Documentación del Tema 05](tema05/README_Tema05.md)
- [Informe final](tema05/Informe_Tema05_Santisteban.pdf)
- [Proyecto SSIS](tema05/DataSaludT05_ETL/)
- [Evidencias de ejecución](tema05/evidencias/)
- [Verificación SQL](tema05/Tema5_Verificacion_SQL.sql)

## Continuidad académica

Los cinco laboratorios representan una evolución
progresiva del caso DataSalud Perú:

1. Programación y validación de datos.
2. Automatización de procesos.
3. Seguridad, rendimiento y recuperación.
4. Integración de bases relacionales y documentales.
5. Integración ETL y almacenamiento dimensional.

Todos los datos utilizados son sintéticos y tienen
fines exclusivamente académicos.

## Versionado

Repositorio: [robinsonSanti02/CIIN1021P_LAB](https://github.com/robinsonSanti02/CIIN1021P_LAB).

Las carpetas `tema01/` a `tema05/` contienen los scripts,
informes, evidencias y documentación de cada laboratorio.

El archivo `.gitignore` excluye archivos temporales,
respaldos, archivos de bases de datos y credenciales.

Los commits deben describir el objetivo de cada cambio.
