# Tema 05 — Almacén de datos y procesos ETL

**Curso:** Base de Datos Avanzadas y Big Data — CIIN1021P  
**Caso:** DataSalud Perú / DIRESA La Libertad  
**Estudiante:** Robinson Jair Santisteban Llaguento  
**Docente:** Ing. Andrés E. Araujo Acuña  
**Fecha:** 24 de noviembre de 2026

## Objetivo

Integrar datos de atención de los orígenes NUCLEO, HIS y CAMPANIA en un almacén dimensional de SQL Server; aplicar ETL con SSIS, control de calidad, cargas incrementales e indicadores por territorio, tiempo y etapa de vida. Ampliar el modelo al proceso de vacunación con dimensiones conformadas.

Todos los registros de la práctica son sintéticos.

## Contenido

| Archivo | Descripción |
|---|---|
| `00_Preparacion_DataSalud_T05.sql` | Preparación de `BDDataSaludTema05` y datos de origen. |
| `Tema5_Ejercicio01.sql` | Indicadores operacionales, filtro de validez y promedio ponderado. |
| `Tema5_Ejercicio02.sql` | Modelo estrella y primera carga de atenciones. |
| `Tema5_Ejercicio03.sql` | Alternativa SQL de extracción, transformación y clasificación de fuentes. |
| `Tema5_Ejercicio04.sql` | Registro de ejecuciones, carga transaccional incremental e indicador mensual. |
| `Tema5_Ejercicio05.sql` | Dimensión de grupo etario, edad a fecha de atención, indicadores y control de campos personales. |
| `Tema5_Ejercicio06.sql` | DimVacuna, FactVacunacion, carga repetible, cobertura y drill-across. |
| `Tema5_Verificacion_SQL.sql` | Consultas de comprobación final de solo lectura. |
| [`DataSaludT05_ETL/`](DataSaludT05_ETL/) | Solución original de Visual Studio y paquete SSIS. |
| [`evidencias/`](evidencias/) | 38 capturas de los ejercicios 01 al 06. |
| [Informe_Tema05_Santisteban.pdf](Informe_Tema05_Santisteban.pdf) | Informe final con evidencias y conclusiones. |

Los scripts están en la raíz de `tema05`, con nombres uniformes al Tema 04. Las menciones a `SQL/EjercicioNN-Tema05.sql` que pudieran aparecer en versiones del informe corresponden a `Tema5_EjercicioNN.sql` en esta entrega.

## Reproducción de la práctica

Requisitos: SQL Server (preferentemente 2022 o la versión utilizada en el laboratorio), SSMS y, para la ruta SSIS, Visual Studio 2022 con la extensión de proyectos de Integration Services y el proveedor OLE DB de SQL Server compatible.

Utilizar una instancia de práctica; no ejecutar los scripts de preparación ni de transformación sobre una base de producción.

1. Ejecutar `00_Preparacion_DataSalud_T05.sql` en una base de práctica recién preparada.
2. Ejecutar los ejercicios 01, 02 y 03 en ese orden.
3. Ejecutar el ejercicio 04. Realiza dos cargas sobre el lote inicial y agrega HIS-005 y CAM-005 a las fuentes.
4. Para procesar el nuevo lote, ejecutar dos veces el paquete SSIS completo, o repetir los scripts 03 y 04 en SSMS. No es necesario hacer ambas alternativas.
5. Ejecutar los ejercicios 05 y 06.
6. Ejecutar `Tema5_Verificacion_SQL.sql` y contrastar los resultados con las capturas.

Los identificadores del log pueden variar en otra instancia. Si el ejercicio 06 ya fue cargado, las siguientes ejecuciones deben conservar las siete dosis y no insertar duplicados.

### Proyecto SSIS

Abrir `DataSaludT05_ETL/DataSaludT05_ETL.sln`, comprobar el administrador de conexiones `CN_DataSaludT05` y seleccionar el servidor local que aloja `BDDataSaludTema05`.

Flujo de control: `SQL_PrepararE03` → `DFT_E03_ExtraerAStaging` → `DFT_E03_TransformarClasificar` → `SQL_CargarDW`.

La copia conserva los archivos originales del proyecto, incluidos sus ajustes de conexión y protección. El proyecto utiliza autenticación integrada de Windows y la configuración original `EncryptSensitiveWithUserKey`. Antes de compartir públicamente, revisar el nombre del servidor y, en Visual Studio, configurar `DontSaveSensitive` en proyecto y paquete si corresponde; guardar y comprobar la conexión. No incorporar contraseñas ni archivos de usuario, compilación o caché al repositorio. Las capturas pueden mostrar el nombre del equipo del laboratorio.

## Resultados observados

| Indicador | Resultado |
|---|---:|
| Atenciones válidas en el DW | 12 |
| Duración total (minutos) | 190 |
| Registros de vacunación de origen | 8 |
| Códigos de dosis distintos | 7 |
| Inserciones de vacunación, primera carga | 7 |
| Inserciones de vacunación, segunda carga | 0 |
| Dosis almacenadas | 7 |
| Duplicados en FactVacunacion | 0 |

### Cobertura de SIM-V (2026) y contraste de procesos

| Provincia | Primeras dosis | Población objetivo | Cobertura | Atenciones de vacunación | Dosis aplicadas |
|---|---:|---:|---:|---:|---:|
| Chepén | 1 | 2 | 50 % | 1 | 2 |
| Sánchez Carrión | 1 | 4 | 25 % | 0 | 1 |
| Trujillo | 3 | 6 | 50 % | 4 | 4 |

Las primeras dosis se dividen entre la población objetivo. El drill-across agrega cada tabla de hechos por provincia y año antes de combinar los resultados; los hechos representan procesos distintos.

## Evidencias

- 01–08: indicadores y modelo dimensional.
- 09–18: extracción, transformación y calidad en SSIS.
- 19–26: carga incremental, log e indicador mensual.
- 27–34: clasificación por edad, privacidad y diagrama físico.
- 35–38: validación previa, carga de vacunación, cobertura, drill-across y comprobaciones finales.

Las capturas documentan ejecuciones realizadas en el laboratorio. Los archivos SQL de los ejercicios 01–05 se conservaron; el ejercicio 06 se adecuó al código ejecutado y se agregó un script de verificación. No se ha vuelto a ejecutar este paquete consolidado en una instancia nueva.

## Continuidad del laboratorio

El Tema 05 continúa el caso DataSalud del Tema 04, pasando del registro operacional y la integración de datos a un modelo dimensional orientado a indicadores analíticos.

[Volver a la raíz del repositorio](../)
