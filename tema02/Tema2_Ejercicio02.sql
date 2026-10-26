USE BDDataSaludTema01;
GO

IF OBJECT_ID('dbo.AlertaAtencion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AlertaAtencion(
        AlertaId INT IDENTITY(1,1)
            CONSTRAINT PK_AlertaAtencion PRIMARY KEY,
        AtencionId INT NOT NULL,
        DuracionMinutos INT NOT NULL,
        Motivo VARCHAR(200) NOT NULL,
        EstadoRevision VARCHAR(15) NOT NULL
            CONSTRAINT DF_AlertaAtencion_Estado DEFAULT ('PENDIENTE'),
        FechaAlerta DATETIME2 NOT NULL
            CONSTRAINT DF_AlertaAtencion_Fecha DEFAULT (SYSDATETIME()),
        UsuarioBD NVARCHAR(128) NOT NULL,
        CONSTRAINT CK_AlertaAtencion_Estado
            CHECK (EstadoRevision IN ('PENDIENTE','REVISADO'))
    );
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Atencion_ValidarEstablecimiento
ON dbo.Atencion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(EstablecimientoId)
       AND EXISTS (
           SELECT 1
           FROM inserted AS I
           INNER JOIN dbo.EstablecimientoSalud AS E
               ON I.EstablecimientoId = E.EstablecimientoId
           WHERE E.Estado <> 'A'
       )
    BEGIN
        THROW 51001,
            'No se puede registrar una atencion en un establecimiento inactivo.', 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Atencion_AlertaDuracion
ON dbo.Atencion
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.AlertaAtencion
        (AtencionId, DuracionMinutos, Motivo, UsuarioBD)
    SELECT
        I.AtencionId,
        I.DuracionMinutos,
        'Duracion mayor a 180 minutos; requiere revision.',
        SUSER_SNAME()
    FROM inserted AS I
    WHERE I.DuracionMinutos > 180;

    IF @@ROWCOUNT > 0
        PRINT 'ALERTA: se registro una atencion con duracion atipica. Revise dbo.AlertaAtencion.';
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Paciente_EvitarEliminacion
ON dbo.Paciente
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE P
    SET P.Estado = 'I'
    FROM dbo.Paciente AS P
    INNER JOIN deleted AS D
        ON D.PacienteId = P.PacienteId;

    PRINT CONCAT('Se marcaron ', @@ROWCOUNT,
        ' paciente(s) como inactivos. No se elimino nada.');
END;
GO

BEGIN TRY
    INSERT INTO dbo.Atencion
        (PacienteId, EstablecimientoId, TipoAtencion,
         DuracionMinutos, ClasificacionDuracion)
    VALUES (1, 3, 'CONSULTA', 20, 'REGULAR');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;

SELECT COUNT(*) AS AtencionesEnEST003
FROM dbo.Atencion
WHERE EstablecimientoId = 3;
GO

DECLARE @Id INT;

INSERT INTO dbo.Atencion
    (PacienteId, EstablecimientoId, TipoAtencion,
     DuracionMinutos, ClasificacionDuracion)
VALUES (1, 1, 'CONSULTA', 200, 'PROLONGADA');

SET @Id = CONVERT(INT, SCOPE_IDENTITY());

SELECT AlertaId, AtencionId, DuracionMinutos, EstadoRevision
FROM dbo.AlertaAtencion
WHERE AtencionId = @Id;

DELETE FROM dbo.Atencion
WHERE AtencionId = @Id;
GO

DELETE FROM dbo.Paciente
WHERE CodigoPaciente = 'PAC-002';

SELECT CodigoPaciente, Estado AS EstadoDespuesDelDELETE
FROM dbo.Paciente
WHERE CodigoPaciente = 'PAC-002';

UPDATE dbo.Paciente
SET Estado = 'A'
WHERE CodigoPaciente = 'PAC-002';

SELECT CodigoPaciente, Estado AS EstadoRestaurado
FROM dbo.Paciente
WHERE CodigoPaciente = 'PAC-002';
GO

DECLARE @A INT;
DECLARE @C VARCHAR(20);
DECLARE @M VARCHAR(300);

BEGIN TRY
    EXEC dbo.usp_RegistrarAtencion
        @PacienteId = 1,
        @EstablecimientoId = 3,
        @TipoAtencion = 'CONSULTA',
        @DuracionMinutos = 20,
        @AtencionId = @A OUTPUT,
        @Clasificacion = @C OUTPUT,
        @Mensaje = @M OUTPUT;
END TRY
BEGIN CATCH
    SELECT 'Procedimiento' AS Camino,
           ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;

BEGIN TRY
    INSERT INTO dbo.Atencion
        (PacienteId, EstablecimientoId, TipoAtencion,
         DuracionMinutos, ClasificacionDuracion)
    VALUES (1, 3, 'CONSULTA', 20, 'REGULAR');
END TRY
BEGIN CATCH
    SELECT 'INSERT directo' AS Camino,
           ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO
