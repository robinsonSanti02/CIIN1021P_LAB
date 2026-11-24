-- CIIN1021P | TEMA 05 | EJERCICIO 06
-- Version reconstruida a partir del codigo ejecutado y las capturas del laboratorio.
-- Ejecutar despues de los ejercicios 01 a 05.
USE BDDataSaludTema05;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
IF OBJECT_ID('dw.DimVacuna', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimVacuna (
        VacunaKey INT IDENTITY(1,1) PRIMARY KEY,
        Vacuna VARCHAR(50) NOT NULL UNIQUE
    );
END;
GO
IF OBJECT_ID('dw.FactVacunacion', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactVacunacion (
        CodigoDosis VARCHAR(50) NOT NULL PRIMARY KEY,
        FechaKey INT NOT NULL,
        EstablecimientoKey INT NOT NULL,
        GrupoEtarioKey INT NOT NULL,
        VacunaKey INT NOT NULL,
        NumeroDosis INT NOT NULL,
        CantidadDosis INT NOT NULL DEFAULT 1,
        CONSTRAINT FK_FactVacunacion_Fecha FOREIGN KEY (FechaKey) REFERENCES dw.DimFecha(FechaKey),
        CONSTRAINT FK_FactVacunacion_Establecimiento FOREIGN KEY (EstablecimientoKey) REFERENCES dw.DimEstablecimiento(EstablecimientoKey),
        CONSTRAINT FK_FactVacunacion_GrupoEtario FOREIGN KEY (GrupoEtarioKey) REFERENCES dw.DimGrupoEtario(GrupoEtarioKey),
        CONSTRAINT FK_FactVacunacion_Vacuna FOREIGN KEY (VacunaKey) REFERENCES dw.DimVacuna(VacunaKey),
        CONSTRAINT CK_FactVacunacion_NumeroDosis CHECK (NumeroDosis > 0),
        CONSTRAINT CK_FactVacunacion_CantidadDosis CHECK (CantidadDosis = 1)
    );
END;
GO
CREATE OR ALTER PROCEDURE etl.usp_CargarVacunacionDW
    @FilasInsertadas INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @FilasInsertadas = 0;
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT DISTINCT CodigoDosis, FechaAplicacion, CodigoEstablecimiento,
            UPPER(LTRIM(RTRIM(Vacuna))) AS Vacuna, NumeroDosis, CodigoPaciente
        INTO #VacunacionUnica
        FROM src.VacunaAplicada;
        IF EXISTS (SELECT CodigoDosis FROM #VacunacionUnica GROUP BY CodigoDosis HAVING COUNT(*) > 1)
        BEGIN
            THROW 50001, 'Existen codigos de dosis con datos diferentes.', 1;
        END;
        IF EXISTS (SELECT 1 FROM #VacunacionUnica WHERE CodigoDosis IS NULL OR FechaAplicacion IS NULL
            OR CodigoEstablecimiento IS NULL OR Vacuna IS NULL OR Vacuna = '' OR NumeroDosis IS NULL OR NumeroDosis <= 0)
        BEGIN
            THROW 50002, 'Existen registros de vacunacion invalidos.', 1;
        END;
        INSERT INTO dw.DimVacuna (Vacuna)
        SELECT DISTINCT V.Vacuna FROM #VacunacionUnica V
        WHERE NOT EXISTS (SELECT 1 FROM dw.DimVacuna D WITH (UPDLOCK, HOLDLOCK) WHERE D.Vacuna = V.Vacuna);
        SELECT V.CodigoDosis, F.FechaKey, E.EstablecimientoKey,
            ISNULL(G.GrupoEtarioKey, 0) AS GrupoEtarioKey, D.VacunaKey, V.NumeroDosis, 1 AS CantidadDosis
        INTO #CargaVacunacion
        FROM #VacunacionUnica V
        LEFT JOIN dw.DimFecha F ON F.Fecha = V.FechaAplicacion
        LEFT JOIN dw.DimEstablecimiento E ON E.CodigoEstablecimiento = V.CodigoEstablecimiento
        LEFT JOIN dw.DimVacuna D ON D.Vacuna = V.Vacuna
        LEFT JOIN ope.Paciente P ON P.CodigoPaciente = V.CodigoPaciente
        OUTER APPLY (SELECT etl.ufn_EdadEnFecha(P.FechaNacimiento, V.FechaAplicacion) AS Edad) A
        OUTER APPLY (
            SELECT TOP (1) GE.GrupoEtarioKey FROM dw.DimGrupoEtario GE
            WHERE GE.GrupoEtarioKey <> 0 AND A.Edad >= GE.EdadMinima
                AND (GE.EdadMaxima IS NULL OR A.Edad <= GE.EdadMaxima)
            ORDER BY GE.EdadMinima DESC
        ) G;
        IF EXISTS (SELECT 1 FROM #CargaVacunacion WHERE FechaKey IS NULL OR EstablecimientoKey IS NULL OR VacunaKey IS NULL)
        BEGIN
            THROW 50003, 'No se encontraron todas las claves dimensionales.', 1;
        END;
        INSERT INTO dw.FactVacunacion (CodigoDosis, FechaKey, EstablecimientoKey, GrupoEtarioKey, VacunaKey, NumeroDosis, CantidadDosis)
        SELECT V.CodigoDosis, V.FechaKey, V.EstablecimientoKey, V.GrupoEtarioKey, V.VacunaKey, V.NumeroDosis, V.CantidadDosis
        FROM #CargaVacunacion V
        WHERE NOT EXISTS (SELECT 1 FROM dw.FactVacunacion F WITH (UPDLOCK, HOLDLOCK) WHERE F.CodigoDosis = V.CodigoDosis);
        SET @FilasInsertadas = @@ROWCOUNT;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SET @FilasInsertadas = 0;
        THROW;
    END CATCH;
END;
GO
SELECT COUNT(*) AS RegistrosOrigen, COUNT(DISTINCT CodigoDosis) AS DosisUnicas FROM src.VacunaAplicada;
SELECT CodigoDosis, COUNT(*) AS Repeticiones FROM src.VacunaAplicada GROUP BY CodigoDosis HAVING COUNT(*) > 1;
GO
DECLARE @PrimeraCarga INT, @SegundaCarga INT;
DECLARE @Resultados TABLE (Ejecucion VARCHAR(30), FilasInsertadas INT, TotalRegistros INT, TotalDosis INT);
EXEC etl.usp_CargarVacunacionDW @FilasInsertadas = @PrimeraCarga OUTPUT;
INSERT INTO @Resultados SELECT 'PRIMERA CARGA', @PrimeraCarga, COUNT(*), ISNULL(SUM(CantidadDosis), 0) FROM dw.FactVacunacion;
EXEC etl.usp_CargarVacunacionDW @FilasInsertadas = @SegundaCarga OUTPUT;
INSERT INTO @Resultados SELECT 'SEGUNDA CARGA', @SegundaCarga, COUNT(*), ISNULL(SUM(CantidadDosis), 0) FROM dw.FactVacunacion;
SELECT * FROM @Resultados;
GO
SELECT * FROM dw.DimVacuna;
SELECT * FROM dw.FactVacunacion ORDER BY CodigoDosis;
GO
CREATE OR ALTER VIEW dw.vw_CoberturaVacunacionProvincia
AS
WITH PrimerasDosis AS (
    SELECT E.Provincia, F.Anio, V.Vacuna, SUM(FV.CantidadDosis) AS PrimerasDosis
    FROM dw.FactVacunacion FV
    INNER JOIN dw.DimEstablecimiento E ON FV.EstablecimientoKey = E.EstablecimientoKey
    INNER JOIN dw.DimFecha F ON FV.FechaKey = F.FechaKey
    INNER JOIN dw.DimVacuna V ON FV.VacunaKey = V.VacunaKey
    WHERE FV.NumeroDosis = 1
    GROUP BY E.Provincia, F.Anio, V.Vacuna
)
SELECT P.Provincia, P.Anio, P.Vacuna, ISNULL(D.PrimerasDosis, 0) AS PrimerasDosis,
    P.Poblacion AS PoblacionObjetivo,
    CAST(100.0 * ISNULL(D.PrimerasDosis, 0) / NULLIF(P.Poblacion, 0) AS DECIMAL(10,2)) AS CoberturaPorcentaje
FROM ope.PoblacionObjetivo P
LEFT JOIN PrimerasDosis D ON P.Provincia = D.Provincia AND P.Anio = D.Anio AND P.Vacuna = D.Vacuna;
GO
SELECT * FROM dw.vw_CoberturaVacunacionProvincia WHERE Anio = 2026 AND Vacuna = 'SIM-V' ORDER BY Provincia;
GO
CREATE OR ALTER VIEW dw.vw_DrillAcrossVacunacion
AS
WITH Atenciones AS (
    SELECT E.Provincia, F.Anio, COUNT(*) AS AtencionesVacunacion
    FROM dw.FactAtencion A
    INNER JOIN dw.DimEstablecimiento E ON A.EstablecimientoKey = E.EstablecimientoKey
    INNER JOIN dw.DimFecha F ON A.FechaKey = F.FechaKey
    INNER JOIN dw.DimTipoAtencion T ON A.TipoAtencionKey = T.TipoAtencionKey
    WHERE T.TipoAtencion = 'VACUNACION'
    GROUP BY E.Provincia, F.Anio
), Vacunaciones AS (
    SELECT E.Provincia, F.Anio, SUM(V.CantidadDosis) AS DosisAplicadas
    FROM dw.FactVacunacion V
    INNER JOIN dw.DimEstablecimiento E ON V.EstablecimientoKey = E.EstablecimientoKey
    INNER JOIN dw.DimFecha F ON V.FechaKey = F.FechaKey
    GROUP BY E.Provincia, F.Anio
)
SELECT COALESCE(A.Provincia, V.Provincia) AS Provincia, COALESCE(A.Anio, V.Anio) AS Anio,
    ISNULL(A.AtencionesVacunacion, 0) AS AtencionesVacunacion, ISNULL(V.DosisAplicadas, 0) AS DosisAplicadas
FROM Atenciones A FULL OUTER JOIN Vacunaciones V ON A.Provincia = V.Provincia AND A.Anio = V.Anio;
GO
SELECT * FROM dw.vw_DrillAcrossVacunacion WHERE Anio = 2026 ORDER BY Provincia;
SELECT G.EtapaVida, COUNT(*) AS Registros, SUM(V.CantidadDosis) AS DosisAplicadas
FROM dw.FactVacunacion V INNER JOIN dw.DimGrupoEtario G ON V.GrupoEtarioKey = G.GrupoEtarioKey
GROUP BY G.EtapaVida ORDER BY G.EtapaVida;
SELECT COUNT(*) AS TotalAtenciones, SUM(DuracionMinutos) AS TotalMinutos FROM dw.FactAtencion;
SELECT COUNT(*) AS TotalRegistrosVacunacion, COUNT(DISTINCT CodigoDosis) AS CodigosUnicos,
    SUM(CantidadDosis) AS TotalDosis, COUNT(*) - COUNT(DISTINCT CodigoDosis) AS Duplicados FROM dw.FactVacunacion;
SELECT COUNT(*) AS RegistrosOrigenConservados FROM src.VacunaAplicada;
GO
