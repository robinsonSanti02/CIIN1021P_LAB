# CIIN1021P_LAB — Laboratorio del Tema 01

**Universidad:** Universidad Privada del Norte  
**Carrera:** Ingeniería de Sistemas Computacionales  
**Curso:** Base de Datos Avanzadas y Big Data  
**Docente:** Ing. Andrés E. Araujo Acuña  
**Autor:** SANTISTEBAN LLAGUENTO ROBINSON JAIR  
**Caso de estudio:** DataSalud Perú

## Propósito y alcance

Aplicar programación T-SQL para validar atenciones de salud, centralizar reglas de negocio, controlar errores y evaluar la calidad de los datos. Los registros del laboratorio son sintéticos.

El repositorio reúne los ejercicios 00 al 04 y la ampliación 05–06. El análisis ético, las respuestas de cierre y el informe acompañan a los scripts. El repositorio de laboratorios se mantiene separado del repositorio del desafío DataSalud.

## Archivos

| Archivo | Contenido |
|---|---|
| [etica_tema01.md](tema01/etica_tema01.md) | Ejercicio 00: dos situaciones reales, fuentes y un dilema ético. |
| [Tema1_Ejercicio01.sql](tema01/Tema1_Ejercicio01.sql) | Base de práctica, tablas, datos, validaciones con IF/CASE y ciclo WHILE. |
| [Tema1_Ejercicio02.sql](tema01/Tema1_Ejercicio02.sql) | Función escalar de clasificación y consultas de prueba. |
| [Tema1_Ejercicio03.sql](tema01/Tema1_Ejercicio03.sql) | Procedimiento de registro con OUTPUT, TRY...CATCH y THROW. |
| [Tema1_Ejercicio04.sql](tema01/Tema1_Ejercicio04.sql) | Staging, evaluación de calidad, detalle y conteo de problemas. |
| [Tema1_Ejercicio05.sql](tema01/Tema1_Ejercicio05.sql) | Función tabular de registros aptos y pruebas de dos lotes. |
| [Tema1_Ejercicio06.sql](tema01/Tema1_Ejercicio06.sql) | Inactivación de pacientes y reporte por rango de fechas. |
| [Respuestas_Cierre.md](tema01/Respuestas_Cierre.md) | Seis respuestas de cierre y reflexiones sobre reutilización y revisión de valores atípicos. |
| [Informe_Tema01_Santisteban.pdf](tema01/Informe_Tema01_Santisteban.pdf) | Evidencias de ejecución, análisis de resultados, conclusiones y referencias. |

## Entorno y orden de ejecución

Se requiere SQL Server 2016 SP1 o posterior y SQL Server Management Studio (SSMS), según la guía del curso.

1. Abrir los archivos SQL en SSMS y conectarse a la instancia de práctica.
2. Ejecutar `Tema1_Ejercicio01.sql` una sola vez para preparar la base.
3. Ejecutar `Tema1_Ejercicio02.sql` y, después, `Tema1_Ejercicio03.sql`.
4. Para reproducir la evaluación de calidad y la ampliación, continuar con los ejercicios 04, 05 y 06, en ese orden.

**Preparación de la base:** el script 01 elimina y vuelve a crear `BDDataSaludTema01`. Debe utilizarse únicamente en el entorno de práctica, conservando antes cualquier trabajo necesario. No se debe repetir entre ejercicios.

Las tres llamadas válidas del ejercicio 03 insertan una atención cada una; repetirlas añade registros. El ejercicio 04 vuelve a crear `AtencionStaging`, por lo que debe ejecutarse antes del 05. Estas dependencias son necesarias para reproducir los conteos de referencia.

## Resultados de referencia

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

## Versionado

Repositorio: [robinsonSanti02/CIIN1021P_LAB](https://github.com/robinsonSanti02/CIIN1021P_LAB).

La carpeta `tema01/` concentra los scripts y documentos del laboratorio. El archivo `.gitignore` excluye respaldos de SQL Server, archivos de la base, CSV, archivos de entorno y archivos cuyo nombre empieza por `secretos`. Los commits deben describir el objetivo de cada cambio.
