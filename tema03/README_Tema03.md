# Guía 3 — Base de Datos Avanzadas y Big Data

## Contenido

- `Tema3_Ejercicio01.sql`: transacciones, stock y vacunaciones.
- `Tema3_Ejercicio02.sql`: logins, usuarios, roles y permisos.
- `Tema3_Ejercicio03.sql`: datos sensibles y registro de accesos.
- `Tema3_Ejercicio04.sql`: planes de ejecución e índices.
- `Tema3_Ejercicio05.sql`: FULL, DIFFERENTIAL, VERIFYONLY, restauración y procedimiento de respaldo.

## Ejecución

Los archivos fueron preparados como ejercicios reproducibles para SQL Server Management Studio.
El script puente del profesor reconstruye `BDDataSaludTema01` y destruye la base anterior: **no ejecutar sin respaldo previo**.
En un entorno de laboratorio limpio, ejecutar los ejercicios en orden del 01 al 05. No ejecutar nuevamente los scripts si se desea conservar el estado actual de la instancia.
`Tema3_Ejercicio05.sql` reconstruye `EvidenciaBackupTema03`, puede sobrescribir sus archivos `.bak` con `INIT` y elimina/recrea la base de pruebas `BDDataSaludTema03_Restore`.

## Evidencias observadas en SSMS (9 de noviembre de 2026)

- Ejercicio 01: cuatro pruebas de transacciones correctas.
- Ejercicio 02: errores 229 esperados y dispensación controlada por procedimiento.
- Ejercicio 03: seis pruebas correctas, incluidos errores 230, 229 y 57001.
- Ejercicio 04: consulta A, 259 a 2 lecturas con primer índice; luego 4 con INCLUDE. Consulta B, 259 a 2 con INCLUDE. Los resultados se tomaron de capturas; pueden variar entre ejecuciones.
- Ejercicio 05: base original con tres evidencias y restaurada con dos; programación lógica devuelve DIFF, FULL y error 58001 ante LOG.

## Política de respaldo propuesta

- **Base:** `BDDataSaludTema01` en el laboratorio; trasladar la política al dataset MINSA en el desafío, sin reutilizar datos sintéticos.
- **Frecuencia:** respaldo FULL los domingos y DIFFERENTIAL de lunes a sábado.
- **Ubicación:** carpeta de respaldo del servidor, definida por `InstanceDefaultBackupPath`; en producción, mantener otra copia protegida fuera del servidor.
- **Responsable:** DBA o administrador designado.
- **Verificación:** `WITH CHECKSUM` durante la copia y `RESTORE VERIFYONLY` después de cada respaldo, además de revisión de historial.
- **Prueba de recuperación:** restauración real en base aislada al menos mensualmente y tras cambios relevantes de infraestructura.
- **Retención sugerida:** conservar cuatro ciclos semanales completos con sus diferenciales, ajustable a la política institucional y capacidad. Nunca borrar el FULL requerido por un DIFF vigente.

**Seguridad:** no subir archivos `.bak`, contraseñas, rutas privadas de usuarios ni datos personales reales al repositorio. Los respaldos y sus restauraciones se ejecutan en la instancia local, no desde GitHub.
