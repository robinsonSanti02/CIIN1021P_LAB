USE BDDataSaludTema05;
GO

IF OBJECT_ID(N'etl.EjecucionCarga', N'U') IS NULL
BEGIN
    CREATE TABLE etl.EjecucionCarga (
        EjecucionId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Proceso VARCHAR(40) NOT NULL,
        Inicio DATETIME2(0) NOT NULL DEFAULT (SYSDATETIME()),
        Fin DATETIME2(0) NULL,
        Estado VARCHAR(10) NOT NULL,
        FilasStaging INT NULL,
        FilasValidas INT NULL,
        FilasRechazadas INT NULL,
        FilasInsertadas INT NULL,
        Mensaje NVARCHAR(4000) NULL
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_key_columns
    WHERE parent_object_id = OBJECT_ID(N'dw.FactAtencion')
      AND parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'dw.FactAtencion'), 'EjecucionId', 'ColumnId')
      AND referenced_object_id = OBJECT_ID(N'etl.EjecucionCarga')
)
    ALTER TABLE dw.FactAtencion ADD CONSTRAINT FK_FactAtencion_Ejecucion
        FOREIGN KEY (EjecucionId) REFERENCES etl.EjecucionCarga (EjecucionId);
GO

SELECT v.Origen, v.CodigoAtencion, v.DuracionMinutos
FROM stg.AtencionValida AS v
WHERE NOT EXISTS (
    SELECT 1 FROM dw.FactAtencion AS h
    WHERE h.Origen = v.Origen AND h.CodigoAtencion = v.CodigoAtencion
)
ORDER BY v.Origen, v.CodigoAtencion;
GO

CREATE OR ALTER PROCEDURE etl.usp_CargarAtencionesDW
    @FilasInsertadas INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @EjecucionId INT;
    SET @FilasInsertadas = 0;

    INSERT INTO etl.EjecucionCarga (Proceso, Estado, FilasStaging, FilasValidas, FilasRechazadas)
    SELECT 'CARGA_DW_ATENCION', 'EN_CURSO',
           (SELECT COUNT(*) FROM stg.Atencion),
           (SELECT COUNT(*) FROM stg.AtencionValida),
           (SELECT COUNT(*) FROM stg.AtencionRechazada);
    SET @EjecucionId = SCOPE_IDENTITY();

    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO dw.DimTipoAtencion (TipoAtencion)
        SELECT DISTINCT v.TipoAtencion FROM stg.AtencionValida AS v
        WHERE NOT EXISTS (
            SELECT 1 FROM dw.DimTipoAtencion AS d WHERE d.TipoAtencion = v.TipoAtencion
        );

        IF EXISTS (
            SELECT 1 FROM stg.AtencionValida AS v
            LEFT JOIN dw.DimFecha AS f ON f.Fecha = v.FechaAtencion
            LEFT JOIN dw.DimEstablecimiento AS e ON e.CodigoEstablecimiento = v.CodigoEstablecimiento
            LEFT JOIN dw.DimTipoAtencion AS t ON t.TipoAtencion = v.TipoAtencion
            WHERE f.FechaKey IS NULL OR e.EstablecimientoKey IS NULL OR t.TipoAtencionKey IS NULL
        )
        BEGIN
            THROW 50001, 'Hay atenciones validas sin correspondencia dimensional.', 1;
        END;

        INSERT INTO dw.FactAtencion
            (Origen, CodigoAtencion, FechaKey, EstablecimientoKey, TipoAtencionKey,
             DuracionMinutos, EjecucionId)
        SELECT v.Origen, v.CodigoAtencion, f.FechaKey, e.EstablecimientoKey,
               t.TipoAtencionKey, v.DuracionMinutos, @EjecucionId
        FROM stg.AtencionValida AS v
        INNER JOIN dw.DimFecha AS f ON f.Fecha = v.FechaAtencion
        INNER JOIN dw.DimEstablecimiento AS e ON e.CodigoEstablecimiento = v.CodigoEstablecimiento
        INNER JOIN dw.DimTipoAtencion AS t ON t.TipoAtencion = v.TipoAtencion
        WHERE NOT EXISTS (
            SELECT 1 FROM dw.FactAtencion AS h
            WHERE h.Origen = v.Origen AND h.CodigoAtencion = v.CodigoAtencion
        );
        SET @FilasInsertadas = @@ROWCOUNT;

        UPDATE etl.EjecucionCarga
        SET Fin = SYSDATETIME(), Estado = 'OK', FilasInsertadas = @FilasInsertadas
        WHERE EjecucionId = @EjecucionId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @FilasInsertadas = 0;
        UPDATE etl.EjecucionCarga
        SET Fin = SYSDATETIME(), Estado = 'ERROR', FilasInsertadas = 0, Mensaje = ERROR_MESSAGE()
        WHERE EjecucionId = @EjecucionId;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER VIEW dw.vw_KpiAtencionProvinciaMes
AS
SELECT e.Provincia, YEAR(f.Fecha) AS Anio, MONTH(f.Fecha) AS Mes,
       COUNT(*) AS Atenciones, SUM(h.DuracionMinutos) AS MinutosTotales,
       CAST(AVG(CAST(h.DuracionMinutos AS DECIMAL(10,2))) AS DECIMAL(6,2)) AS PromedioMinutos
FROM dw.FactAtencion AS h
INNER JOIN dw.DimFecha AS f ON f.FechaKey = h.FechaKey
INNER JOIN dw.DimEstablecimiento AS e ON e.EstablecimientoKey = h.EstablecimientoKey
GROUP BY e.Provincia, YEAR(f.Fecha), MONTH(f.Fecha);
GO

DECLARE @Nuevas INT;
EXEC etl.usp_CargarAtencionesDW @FilasInsertadas = @Nuevas OUTPUT;
SELECT 1 AS Pasada, @Nuevas AS Insertadas, COUNT(*) AS Hechos,
       SUM(DuracionMinutos) AS MinutosTotales FROM dw.FactAtencion;
EXEC etl.usp_CargarAtencionesDW @FilasInsertadas = @Nuevas OUTPUT;
SELECT 2 AS Pasada, @Nuevas AS Insertadas, COUNT(*) AS Hechos,
       SUM(DuracionMinutos) AS MinutosTotales FROM dw.FactAtencion;

IF NOT EXISTS (SELECT 1 FROM src.AtencionHIS WHERE CodigoAtencion = 'HIS-005')
    INSERT INTO src.AtencionHIS
        (CodigoAtencion, FechaAtencion, CodigoEstablecimiento, TipoAtencion,
         DuracionMinutos, EstadoRegistro, CodigoPaciente)
    VALUES ('HIS-005','20261102','EST-004','LABORATORIO',30,'VALIDO','PAC-0004');

IF NOT EXISTS (SELECT 1 FROM src.AtencionCampania WHERE CodigoAtencion = 'CAM-005')
    INSERT INTO src.AtencionCampania
        (CodigoAtencion, FechaAtencion, CodigoEstablecimiento, TipoAtencion,
         DuracionMinutos, EstadoRegistro, CodigoPaciente)
    VALUES ('CAM-005','20261103','est-005','vacuna',7,'V','PAC-0006');

SELECT EjecucionId, Estado, FilasStaging, FilasValidas, FilasRechazadas, FilasInsertadas, Mensaje
FROM etl.EjecucionCarga WHERE Proceso = 'CARGA_DW_ATENCION' ORDER BY EjecucionId;

SELECT Provincia, Anio, Mes, Atenciones, MinutosTotales, PromedioMinutos
FROM dw.vw_KpiAtencionProvinciaMes ORDER BY Provincia, Anio, Mes;
GO
