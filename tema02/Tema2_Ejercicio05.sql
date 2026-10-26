USE BDDataSaludTema01;
GO

IF OBJECT_ID('dbo.ResumenDiarioAtencion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ResumenDiarioAtencion(
        FechaAtencion DATE NOT NULL,
        EstablecimientoId INT NOT NULL,
        TipoAtencion VARCHAR(30) NOT NULL,
        TotalAtenciones INT NOT NULL,
        TotalMinutos INT NOT NULL,
        PromedioMinutos DECIMAL(10,2) NOT NULL,
        FechaCierre DATETIME2 NOT NULL
            CONSTRAINT DF_ResumenDiario_Fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_ResumenDiarioAtencion
            PRIMARY KEY (FechaAtencion, EstablecimientoId, TipoAtencion)
    );
END;
GO

IF OBJECT_ID('dbo.CierreDiario', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CierreDiario(
        CierreId INT IDENTITY(1,1)
            CONSTRAINT PK_CierreDiario PRIMARY KEY,
        FechaAtencion DATE NOT NULL
            CONSTRAINT UQ_CierreDiario_Fecha UNIQUE,
        FilasResumen INT NOT NULL,
        TotalAtenciones INT NOT NULL,
        FechaCierre DATETIME2 NOT NULL
            CONSTRAINT DF_CierreDiario_Fecha DEFAULT (SYSDATETIME()),
        UsuarioBD NVARCHAR(128) NOT NULL
    );
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CerrarDiaAtenciones
    @Fecha DATE,
    @FilasResumen INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalAtenciones INT;

    BEGIN TRY
        SET @FilasResumen = 0;
        SET @Mensaje = NULL;

        IF @Fecha IS NULL
        BEGIN
            THROW 54001, 'La fecha de cierre es obligatoria.', 1;
        END;

        IF @Fecha > CAST(GETDATE() AS DATE)
        BEGIN
            THROW 54002, 'No se puede cerrar una fecha futura.', 1;
        END;

        IF EXISTS (
            SELECT 1
            FROM dbo.CierreDiario
            WHERE FechaAtencion = @Fecha
        )
        BEGIN
            THROW 54003, 'El dia indicado ya fue cerrado.', 1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Atencion
            WHERE FechaAtencion >= @Fecha
              AND FechaAtencion < DATEADD(DAY, 1, @Fecha)
        )
        BEGIN
            THROW 54004, 'No existen atenciones para la fecha indicada.', 1;
        END;

        BEGIN TRANSACTION;

        INSERT INTO dbo.ResumenDiarioAtencion
            (FechaAtencion, EstablecimientoId, TipoAtencion,
             TotalAtenciones, TotalMinutos, PromedioMinutos)
        SELECT
            @Fecha,
            A.EstablecimientoId,
            A.TipoAtencion,
            COUNT(*),
            SUM(A.DuracionMinutos),
            CAST(AVG(CAST(A.DuracionMinutos AS DECIMAL(10,2))) AS DECIMAL(10,2))
        FROM dbo.Atencion AS A
        WHERE A.FechaAtencion >= @Fecha
          AND A.FechaAtencion < DATEADD(DAY, 1, @Fecha)
        GROUP BY A.EstablecimientoId, A.TipoAtencion;

        SET @FilasResumen = @@ROWCOUNT;

        SELECT @TotalAtenciones = SUM(TotalAtenciones)
        FROM dbo.ResumenDiarioAtencion
        WHERE FechaAtencion = @Fecha;

        INSERT INTO dbo.CierreDiario
            (FechaAtencion, FilasResumen, TotalAtenciones, UsuarioBD)
        VALUES
            (@Fecha, @FilasResumen, @TotalAtenciones, SUSER_SNAME());

        COMMIT TRANSACTION;

        SET @Mensaje = CONCAT(
            'Cierre diario confirmado. Filas de resumen: ',
            @FilasResumen,
            '. Total de atenciones: ',
            @TotalAtenciones,
            '.'
        );
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @Mensaje = CONCAT('Error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
        THROW;
    END CATCH;
END;
GO

DECLARE @F INT, @M VARCHAR(300);
BEGIN TRY
    EXEC dbo.usp_CerrarDiaAtenciones
        @Fecha = '2026-09-05',
        @FilasResumen = @F OUTPUT,
        @Mensaje = @M OUTPUT;
    SELECT @F AS FilasResumen, @M AS Mensaje;
END TRY
BEGIN CATCH
    SELECT 'Primer cierre' AS Caso,
           ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO

SELECT FechaAtencion, EstablecimientoId, TipoAtencion,
       TotalAtenciones, TotalMinutos, PromedioMinutos
FROM dbo.ResumenDiarioAtencion
WHERE FechaAtencion = '2026-09-05'
ORDER BY EstablecimientoId, TipoAtencion;
GO

DECLARE @F INT, @M VARCHAR(300);
BEGIN TRY
    EXEC dbo.usp_CerrarDiaAtenciones
        @Fecha = '2026-09-05',
        @FilasResumen = @F OUTPUT,
        @Mensaje = @M OUTPUT;
END TRY
BEGIN CATCH
    SELECT 'Segundo cierre' AS Caso,
           ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;

BEGIN TRY
    EXEC dbo.usp_CerrarDiaAtenciones
        @Fecha = '2026-01-01',
        @FilasResumen = @F OUTPUT,
        @Mensaje = @M OUTPUT;
END TRY
BEGIN CATCH
    SELECT 'Dia sin atenciones' AS Caso,
           ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;

SELECT CierreId, FechaAtencion, FilasResumen, TotalAtenciones
FROM dbo.CierreDiario
ORDER BY FechaAtencion;

SELECT @@TRANCOUNT AS TransaccionesAbiertas;
GO
