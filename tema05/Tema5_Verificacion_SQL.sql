-- Comprobaciones de solo lectura al finalizar los seis ejercicios.
USE BDDataSaludTema05;
GO
SELECT 'Atenciones conservadas' AS Comprobacion, COUNT(*) AS Resultado, 12 AS Esperado FROM dw.FactAtencion
UNION ALL SELECT 'Minutos conservados', SUM(DuracionMinutos), 190 FROM dw.FactAtencion
UNION ALL SELECT 'Registros de vacunacion en origen', COUNT(*), 8 FROM src.VacunaAplicada
UNION ALL SELECT 'Dosis almacenadas', SUM(CantidadDosis), 7 FROM dw.FactVacunacion
UNION ALL SELECT 'Codigos de dosis unicos', COUNT(DISTINCT CodigoDosis), 7 FROM dw.FactVacunacion
UNION ALL SELECT 'Duplicados en el Data Warehouse', COUNT(*) - COUNT(DISTINCT CodigoDosis), 0 FROM dw.FactVacunacion;
GO
SELECT EjecucionId, Estado, FilasStaging, FilasValidas, FilasRechazadas, FilasInsertadas
FROM etl.EjecucionCarga ORDER BY EjecucionId;
SELECT * FROM dw.vw_KpiAtencionProvinciaMes ORDER BY Anio, Mes, Provincia;
SELECT * FROM dw.vw_CoberturaVacunacionProvincia WHERE Anio = 2026 AND Vacuna = 'SIM-V' ORDER BY Provincia;
SELECT * FROM dw.vw_DrillAcrossVacunacion WHERE Anio = 2026 ORDER BY Provincia;
GO
WITH DosisUnicas AS (
    SELECT DISTINCT CodigoDosis, CodigoPaciente, FechaAplicacion FROM src.VacunaAplicada
)
SELECT V.CodigoDosis, V.FechaAplicacion, A.EdadCalculada, G.EtapaVida AS EtapaRegistrada,
    ISNULL(GE.EtapaVida, 'NO REGISTRADO') AS EtapaEsperada,
    CASE WHEN F.GrupoEtarioKey = ISNULL(GE.GrupoEtarioKey, 0) THEN 'CORRECTO' ELSE 'REVISAR' END AS Validacion
FROM DosisUnicas V
INNER JOIN dw.FactVacunacion F ON V.CodigoDosis = F.CodigoDosis
LEFT JOIN ope.Paciente P ON V.CodigoPaciente = P.CodigoPaciente
INNER JOIN dw.DimGrupoEtario G ON F.GrupoEtarioKey = G.GrupoEtarioKey
OUTER APPLY (SELECT DATEDIFF(YEAR, P.FechaNacimiento, V.FechaAplicacion) - CASE
    WHEN DATEADD(YEAR, DATEDIFF(YEAR, P.FechaNacimiento, V.FechaAplicacion), P.FechaNacimiento) > V.FechaAplicacion THEN 1 ELSE 0 END AS EdadCalculada) A
OUTER APPLY (SELECT TOP (1) D.GrupoEtarioKey, D.EtapaVida FROM dw.DimGrupoEtario D
    WHERE D.GrupoEtarioKey <> 0 AND A.EdadCalculada >= D.EdadMinima AND (D.EdadMaxima IS NULL OR A.EdadCalculada <= D.EdadMaxima)
    ORDER BY D.EdadMinima DESC) GE
ORDER BY V.CodigoDosis;
GO
SELECT COUNT(*) AS ColumnasPersonalesEnDW
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dw'
AND COLUMN_NAME IN ('PacienteId','CodigoPaciente','NombreSimulado','DocumentoSimulado','FechaNacimiento','Sexo');
GO
