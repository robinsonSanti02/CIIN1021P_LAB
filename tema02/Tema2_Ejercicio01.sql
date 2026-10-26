USE BDDataSaludTema01;
GO

IF OBJECT_ID('dbo.AuditoriaAtencion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditoriaAtencion
    (
        AuditoriaId BIGINT IDENTITY(1,1)
            CONSTRAINT PK_AuditoriaAtencion PRIMARY KEY,
        AtencionId INT NOT NULL,
        Operacion VARCHAR(10) NOT NULL,
        FechaOperacion DATETIME2 NOT NULL
            CONSTRAINT DF_AuditoriaAtencion_Fecha DEFAULT (SYSDATETIME()),
        UsuarioBD NVARCHAR(128) NOT NULL,
        TerminalBD NVARCHAR(128) NULL,
        AplicacionBD NVARCHAR(128) NULL,
        PacienteIdAnterior INT NULL,
        PacienteIdNuevo INT NULL,
        EstablecimientoIdAnterior INT NULL,
        EstablecimientoIdNuevo INT NULL,
        TipoAtencionAnterior VARCHAR(30) NULL,
        TipoAtencionNuevo VARCHAR(30) NULL,
        DuracionAnterior INT NULL,
        DuracionNueva INT NULL,
        ClasificacionAnterior VARCHAR(20) NULL,
        ClasificacionNueva VARCHAR(20) NULL,
        CONSTRAINT CK_AuditoriaAtencion_Operacion
            CHECK (Operacion IN ('INSERT', 'UPDATE', 'DELETE'))
    );
END;
GO

DROP TRIGGER IF EXISTS dbo.trg_Atencion_Auditoria;
GO

CREATE OR ALTER TRIGGER dbo.trg_Atencion_AuditoriaUnaFila
ON dbo.Atencion
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AtencionId INT, @Duracion INT;

    SELECT
        @AtencionId = AtencionId,
        @Duracion = DuracionMinutos
    FROM inserted;

    INSERT INTO dbo.AuditoriaAtencion
        (AtencionId, Operacion, UsuarioBD, DuracionNueva)
    VALUES
        (@AtencionId, 'INSERT', SUSER_SNAME(), @Duracion);
END;
GO

SET LOCK_TIMEOUT 5000;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @MaxAtencion INT =
        ISNULL((SELECT MAX(AtencionId) FROM dbo.Atencion), 0);

    DECLARE @MaxAuditoria BIGINT =
        ISNULL((SELECT MAX(AuditoriaId) FROM dbo.AuditoriaAtencion), 0);

    INSERT INTO dbo.Atencion
        (PacienteId, EstablecimientoId, TipoAtencion, DuracionMinutos, ClasificacionDuracion)
    VALUES
        (1, 1, 'CONTROL', 10, 'CORTA'),
        (2, 2, 'VACUNACION', 25, 'REGULAR');

    SELECT COUNT(*) AS AtencionesInsertadas
    FROM dbo.Atencion
    WHERE AtencionId > @MaxAtencion;

    SELECT COUNT(*) AS FilasDeAuditoria
    FROM dbo.AuditoriaAtencion
    WHERE AuditoriaId > @MaxAuditoria;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;
END CATCH;

SET LOCK_TIMEOUT -1;
GO

DROP TRIGGER IF EXISTS dbo.trg_Atencion_AuditoriaUnaFila;
GO

CREATE OR ALTER TRIGGER dbo.trg_Atencion_Auditoria
ON dbo.Atencion
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.AuditoriaAtencion
    (
        AtencionId,
        Operacion,
        UsuarioBD,
        TerminalBD,
        AplicacionBD,
        PacienteIdAnterior,
        PacienteIdNuevo,
        EstablecimientoIdAnterior,
        EstablecimientoIdNuevo,
        TipoAtencionAnterior,
        TipoAtencionNuevo,
        DuracionAnterior,
        DuracionNueva,
        ClasificacionAnterior,
        ClasificacionNueva
    )
    SELECT
        COALESCE(I.AtencionId, D.AtencionId),
        CASE
            WHEN D.AtencionId IS NULL THEN 'INSERT'
            WHEN I.AtencionId IS NULL THEN 'DELETE'
            ELSE 'UPDATE'
        END,
        SUSER_SNAME(),
        HOST_NAME(),
        APP_NAME(),
        D.PacienteId,
        I.PacienteId,
        D.EstablecimientoId,
        I.EstablecimientoId,
        D.TipoAtencion,
        I.TipoAtencion,
        D.DuracionMinutos,
        I.DuracionMinutos,
        D.ClasificacionDuracion,
        I.ClasificacionDuracion
    FROM inserted AS I
    FULL OUTER JOIN deleted AS D
        ON I.AtencionId = D.AtencionId
    WHERE
        D.AtencionId IS NULL
        OR I.AtencionId IS NULL
        OR I.PacienteId <> D.PacienteId
        OR I.EstablecimientoId <> D.EstablecimientoId
        OR I.TipoAtencion <> D.TipoAtencion
        OR I.DuracionMinutos <> D.DuracionMinutos
        OR I.ClasificacionDuracion <> D.ClasificacionDuracion;
END;
GO

DECLARE @Id INT;

INSERT INTO dbo.Atencion
    (PacienteId, EstablecimientoId, TipoAtencion,
     DuracionMinutos, ClasificacionDuracion)
VALUES
    (1, 1, 'CONSULTA', 20, 'REGULAR');

SET @Id = CONVERT(INT, SCOPE_IDENTITY());

UPDATE dbo.Atencion
SET DuracionMinutos = 35,
    ClasificacionDuracion = 'PROLONGADA'
WHERE AtencionId = @Id;

UPDATE dbo.Atencion
SET DuracionMinutos = DuracionMinutos
WHERE AtencionId = @Id;

DELETE FROM dbo.Atencion
WHERE AtencionId = @Id;

SELECT
    AuditoriaId,
    AtencionId,
    Operacion,
    DuracionAnterior,
    DuracionNueva,
    ClasificacionAnterior,
    ClasificacionNueva,
    UsuarioBD,
    TerminalBD,
    AplicacionBD
FROM dbo.AuditoriaAtencion
WHERE AtencionId = @Id
ORDER BY AuditoriaId;
GO

DECLARE @Antes BIGINT =
    ISNULL((SELECT MAX(AuditoriaId) FROM dbo.AuditoriaAtencion), 0);

DECLARE @Nuevas TABLE
(
    AtencionId INT PRIMARY KEY
);

INSERT INTO dbo.Atencion
    (PacienteId, EstablecimientoId, TipoAtencion,
     DuracionMinutos, ClasificacionDuracion)
OUTPUT inserted.AtencionId INTO @Nuevas
VALUES
    (1, 1, 'CONTROL', 11, 'CORTA'),
    (2, 2, 'VACUNACION', 26, 'REGULAR');

DELETE A
FROM dbo.Atencion AS A
INNER JOIN @Nuevas AS N
    ON A.AtencionId = N.AtencionId;

SELECT Operacion, COUNT(*) AS Filas
FROM dbo.AuditoriaAtencion
WHERE AuditoriaId > @Antes
GROUP BY Operacion
ORDER BY Operacion;
GO
