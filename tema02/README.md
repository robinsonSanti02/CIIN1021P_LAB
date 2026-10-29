# Tema 02 Automatización y control transaccional

Universidad Privada del Norte  
Curso: Base de Datos Avanzadas y Big Data  
Docente: Ing. Andrés E. Araujo Acuña  
Estudiante: Robinson Jair Santisteban Llaguento

Este laboratorio aplica auditoría, triggers de integridad y alerta, transacciones, cursores y cierre diario sobre `BDDataSaludTema01`. Todos los datos son sintéticos.

## Archivos

| Archivo | Contenido |
|---|---|
| [Tema2_Ejercicio01.sql](Tema2_Ejercicio01.sql) | Tabla de auditoría, demostración del trigger incorrecto, trigger definitivo y pruebas de una y varias filas. |
| [Tema2_Ejercicio02.sql](Tema2_Ejercicio02.sql) | Bloqueo, alertas, eliminación lógica y pruebas de comparación con el procedimiento. |
| [Tema2_Ejercicio03.sql](Tema2_Ejercicio03.sql) | Carga transaccional, SAVEPOINT y ramas CANCELADO, ERROR y CONFIRMADO. |
| [Tema2_Ejercicio04.sql](Tema2_Ejercicio04.sql) | Cursor por fila, registro de rechazos y contraste con la función tabular. |
| [Tema2_Ejercicio05.sql](Tema2_Ejercicio05.sql) | Cierre diario y pruebas de cierre repetido y fecha sin atenciones. |
| [Informe_Tema02_Santisteban.pdf](Informe_Tema02_Santisteban.pdf) | Evidencias, comparación, respuestas, análisis, conclusiones y referencias. |
| [Tema2_VerificacionAuditoria.sql](Tema2_VerificacionAuditoria.sql) | Consulta complementaria de lectura para mostrar usuario, terminal y aplicación en filas separadas. |

## Requisitos

SQL Server y SQL Server Management Studio. La base debe contener `Paciente`, `EstablecimientoSalud`, `Atencion`, `AtencionStaging`, `ufn_ClasificarDuracionAtencion`, `usp_RegistrarAtencion`, `usp_EvaluarCalidadLote` y `ufn_RegistrosAptosCarga`.

PAC-001 y PAC-002 deben estar activos; PAC-003 y EST-003, inactivos. Las tablas y rutinas del Tema 01 incluidas en `../tema01/` permiten preparar el entorno. También puede usarse el script puente proporcionado por el docente al inicio, si la base está ausente o incompleta.

El script puente y el primer ejercicio del Tema 01 borran y reconstruyen la base. No se deben ejecutar para continuar ni para repetir una prueba del Tema 02 sobre un trabajo ya desarrollado.

## Orden de primera ejecución

1. Confirmar los ocho objetos y los estados anteriores en la base de práctica.
2. Ejecutar `Tema2_Ejercicio01.sql` completo y comprobar sus resultados.
3. Ejecutar `Tema2_Ejercicio02.sql`; su prueba deja PAC-002 restaurado a A.
4. Ejecutar `Tema2_Ejercicio03.sql`: cancelación, error simulado y confirmación, en ese orden.
5. Ejecutar `Tema2_Ejercicio04.sql` una sola vez para obtener el detalle del lote.
6. Ejecutar `Tema2_Ejercicio05.sql` después de confirmar LOTE-004.
7. Ejecutar `Tema2_VerificacionAuditoria.sql` para consultar completos los metadatos del último registro auditado. La figura 19 del informe documenta esta verificación.

Al finalizar una prueba, comprobar que `@@TRANCOUNT` sea 0. Antes de continuar, una transacción de prueba que siga abierta debe revertirse. Las figuras 1 a 18 proceden de la ejecución original del 26 de octubre de 2026. La figura 19 muestra la consulta complementaria de lectura aportada el 27 de octubre; no se repitieron los cinco ejercicios para obtenerla.

## Resultados esperados

| Ejercicio | Comprobación |
|---|---|
| 01 | Trigger incorrecto: 2 atenciones y 1 auditoría. Trigger correcto: 3 operaciones individuales; INSERT = 2 y DELETE = 2 en la prueba multirregistro. |
| 02 | 51001 y cero atenciones en EST-003; alerta PENDIENTE de 200 minutos; PAC-002 pasa a I y se restaura a A. Comparación: 50036 por procedimiento y 51001 por trigger. |
| 03 | CANCELADO con 0 filas; ERROR 52004 con 0 filas persistidas; CONFIRMADO con 2 filas en la primera ejecución. Ninguna transacción queda abierta. |
| 04 | 3 cargadas, 2 rechazadas; errores 50033 y 50036; alerta de 210 minutos. La función por conjuntos devuelve 2 registros. |
| 05 | 2 filas de resumen para 2026-09-05; promedios 13.00 y 27.00; errores 54003 y 54004; un único cierre. |

Los IDENTITY pueden variar entre ejecuciones. Se comparan cantidades, estados y valores de negocio, no números de identificador exactos.

## Repetición de pruebas

El ejercicio 03 evita atenciones equivalentes mediante NOT EXISTS. Si LOTE-004 ya fue confirmado, una confirmación posterior puede cargar 0 filas; el historial acumulará nuevos intentos. Esto no reproduce el estado inicial del informe.

El ejercicio 04 no elimina automáticamente las atenciones cargadas en una ejecución anterior. Para repetirlo sobre los mismos datos sintéticos, ejecutar antes esta limpieza tomada del procedimiento de la guía. Conserva el historial de auditoría y de alertas, por lo que las alertas antiguas pueden seguir apareciendo.

```sql
USE BDDataSaludTema01;
GO
DELETE A
FROM dbo.Atencion AS A
INNER JOIN dbo.ResultadoCargaFila AS R
    ON R.AtencionId = A.AtencionId
WHERE R.LoteCarga = 'LOTE-006';

DELETE FROM dbo.ResultadoCargaFila
WHERE LoteCarga = 'LOTE-006';
GO
```

El ejercicio 05 impide cerrar de nuevo una fecha ya cerrada. Al repetirlo, el primer intento puede producir también 54003. No hay que borrar el cierre ni reiniciar la base para ocultar ese comportamiento.

## Ensayo complementario con dos sesiones

Abrir dos consultas conectadas a `BDDataSaludTema01`. En la ventana A ejecutar:

```sql
BEGIN TRANSACTION;
UPDATE dbo.EstablecimientoSalud
SET Provincia = 'Ascope'
WHERE EstablecimientoId = 2;
SELECT @@TRANCOUNT AS TransaccionesAbiertas;
```

Mientras A conserva su transacción, ejecutar en B:

```sql
SET LOCK_TIMEOUT 5000;
SELECT EstablecimientoId, Provincia
FROM dbo.EstablecimientoSalud
WHERE EstablecimientoId = 2;
```

Con READ COMMITTED basado en bloqueos, B puede devolver 1222 al agotar los cinco segundos. Si READ_COMMITTED_SNAPSHOT está activo, puede mostrar la versión confirmada sin esperar; registrar lo que realmente ocurra. Revertir en A:

```sql
ROLLBACK TRANSACTION;
SELECT @@TRANCOUNT AS TransaccionesAbiertas;
```

Volver a B y ejecutar:

```sql
SET LOCK_TIMEOUT -1;
SELECT EstablecimientoId, Provincia
FROM dbo.EstablecimientoSalud
WHERE EstablecimientoId = 2;
```

## Explicaciones complementarias

**Ejercicio 01.** El trigger incorrecto asigna a variables escalares datos de `inserted`, por lo que no conserva todas sus filas. La evidencia muestra 2 atenciones y 1 auditoría. No se atribuye una predicción previa no documentada.

**Ejercicio 03.** El registro ERROR se inserta después del ROLLBACK total porque, si se escribiera dentro de la transacción antes de revertirla, también se desharía. El control CANCELADO sobrevive porque se creó antes del SAVEPOINT y se confirma después de la reversión parcial.

**Ejercicio 04.** El procedimiento del Tema 01 no recibe la fecha original; el cursor utiliza la fecha de ejecución mediante el DEFAULT de `Atencion`. La función por conjuntos rechaza duraciones superiores a 180 minutos y el procedimiento las admite con alerta. La comparación de tiempos requiere antes reglas equivalentes y el mismo volumen.

**Ejercicio 05.** Validar 54003 permite dar un mensaje claro y evitar trabajo innecesario. UNIQUE mantiene la integridad frente a accesos directos y concurrencia; la validación no la sustituye.

## Evidencias y alcance

Las explicaciones se conservan en el informe y en este README, fuera de los SQL. La figura 19 del informe incorpora la captura complementaria con los tres metadatos completos: UsuarioBD, TerminalBD y AplicacionBD. La consulta finalizó correctamente y no modifica datos. El registro observado tiene AuditoriaId 31, AtencionId 28, operación INSERT y FechaOperacion 2026-10-26 16:27:34.2772374. Esa fecha corresponde al evento auditado.

El reto del orquestador y trigger DDL y la medición de tiempos son opcionales y no están incluidos como ejecuciones realizadas. El desafío sobre el dataset del MINSA es una entrega distinta.

El versionado en Git es una recomendación sin nota según la guía. Este paquete no certifica un commit remoto. No se deben publicar datos reales ni respaldos `.bak` de la base.
