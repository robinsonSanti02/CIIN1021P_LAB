USE BDDataSaludTema01;
GO

DROP PROCEDURE IF EXISTS dbo.usp_ConsultarDetalleClinico;
DROP TABLE IF EXISTS dbo.LogAccesoPaciente;
DROP TABLE IF EXISTS dbo.DetalleClinicoRestringido;
GO

CREATE TABLE dbo.DetalleClinicoRestringido(
    DetalleClinicoId INT IDENTITY(1,1)
        CONSTRAINT PK_DetalleClinicoRestringido PRIMARY KEY,
    PacienteId INT NOT NULL
        CONSTRAINT FK_DetalleClinico_Paciente REFERENCES dbo.Paciente(PacienteId),
    NivelRiesgo VARCHAR(10) NOT NULL
        CONSTRAINT CK_DetalleClinico_Riesgo CHECK (NivelRiesgo IN ('BAJO','MEDIO','ALTO')),
    Diagnostico VARCHAR(100) NOT NULL,
    FechaRegistro DATE NOT NULL
        CONSTRAINT DF_DetalleClinico_Fecha DEFAULT (CAST(SYSDATETIME() AS DATE))
);

CREATE TABLE dbo.LogAccesoPaciente(
    LogId BIGINT IDENTITY(1,1)
        CONSTRAINT PK_LogAccesoPaciente PRIMARY KEY,
    Usuario NVARCHAR(128) NOT NULL,
    FechaAcceso DATETIME2 NOT NULL
        CONSTRAINT DF_LogAcceso_Fecha DEFAULT (SYSDATETIME()),
    AccionRealizada VARCHAR(60) NOT NULL,
    PacienteId INT NULL
);
GO

INSERT INTO dbo.DetalleClinicoRestringido (PacienteId, NivelRiesgo, Diagnostico)
VALUES
    (1, 'BAJO', 'Control preventivo (dato sintetico)'),
    (2, 'MEDIO', 'Seguimiento de vacunacion (dato sintetico)'),
    (3, 'ALTO', 'Evaluacion pendiente (dato sintetico)');
GO

GRANT SELECT ON dbo.DetalleClinicoRestringido TO rol_analista;
DENY SELECT ON dbo.DetalleClinicoRestringido (Diagnostico) TO rol_analista;
GO

DENY SELECT ON dbo.DetalleClinicoRestringido TO rol_auditor;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ConsultarDetalleClinico
    @CodigoPaciente VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PacienteId INT;

    SELECT @PacienteId = PacienteId
    FROM dbo.Paciente
    WHERE CodigoPaciente = @CodigoPaciente;

    IF @PacienteId IS NULL
    BEGIN
        ;THROW 57001, 'El codigo del paciente no existe.', 1;
    END;

    INSERT INTO dbo.LogAccesoPaciente (Usuario, AccionRealizada, PacienteId)
    VALUES (SUSER_SNAME(), 'CONSULTA DETALLE CLINICO', @PacienteId);

    SELECT DetalleClinicoId, PacienteId, NivelRiesgo, Diagnostico, FechaRegistro
    FROM dbo.DetalleClinicoRestringido
    WHERE PacienteId = @PacienteId;
END;
GO

DENY SELECT ON dbo.DetalleClinicoRestringido TO rol_administrador;
GRANT EXECUTE ON dbo.usp_ConsultarDetalleClinico TO rol_administrador;
GO

EXECUTE AS LOGIN = 'login_analista';
SELECT PacienteId, NivelRiesgo, FechaRegistro FROM dbo.DetalleClinicoRestringido;
BEGIN TRY
    SELECT PacienteId, Diagnostico FROM dbo.DetalleClinicoRestringido;
END TRY
BEGIN CATCH
    SELECT 'Caso 2' AS Caso, ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
REVERT;
GO

EXECUTE AS LOGIN = 'login_auditor';
BEGIN TRY
    SELECT TOP (1) PacienteId FROM dbo.DetalleClinicoRestringido;
END TRY
BEGIN CATCH
    SELECT 'Caso 3' AS Caso, ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
REVERT;
GO

EXECUTE AS LOGIN = 'login_administrador';
BEGIN TRY
    SELECT * FROM dbo.DetalleClinicoRestringido;
END TRY
BEGIN CATCH
    SELECT 'Caso 4' AS Caso, ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
EXEC dbo.usp_ConsultarDetalleClinico @CodigoPaciente = 'PAC-002';
BEGIN TRY
    EXEC dbo.usp_ConsultarDetalleClinico @CodigoPaciente = 'PAC-999';
END TRY
BEGIN CATCH
    SELECT 'Caso 5' AS Caso, ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
REVERT;
GO

SELECT LogId, Usuario, AccionRealizada, PacienteId
FROM dbo.LogAccesoPaciente
ORDER BY LogId;
GO

SELECT SUSER_SNAME() AS LoginFinal;
GO
