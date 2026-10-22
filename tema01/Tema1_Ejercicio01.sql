--TEMA 01 / EJERCICIO 01
USE master;
GO
IF DB_ID('BDDataSaludTema01') IS NOT NULL
BEGIN
    ALTER DATABASE BDDataSaludTema01 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BDDataSaludTema01;
END;
GO
CREATE DATABASE BDDataSaludTema01;
GO
USE BDDataSaludTema01;
GO

CREATE TABLE dbo.Paciente (
    PacienteId INT IDENTITY(1,1) CONSTRAINT PK_Paciente PRIMARY KEY,
    CodigoPaciente VARCHAR(20) NOT NULL,
    Estado CHAR(1) NOT NULL CONSTRAINT DF_Paciente_Estado DEFAULT ('A'),
    CONSTRAINT UQ_Paciente_Codigo UNIQUE (CodigoPaciente),
    CONSTRAINT CK_Paciente_Estado CHECK (Estado IN ('A','I'))
);
GO
CREATE TABLE dbo.EstablecimientoSalud (
    EstablecimientoId INT IDENTITY(1,1) CONSTRAINT PK_EstablecimientoSalud PRIMARY KEY,
    CodigoEstablecimiento VARCHAR(20) NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Provincia VARCHAR(60) NOT NULL,
    Estado CHAR(1) NOT NULL CONSTRAINT DF_Establecimiento_Estado DEFAULT ('A'),
    CONSTRAINT UQ_Establecimiento_Codigo UNIQUE (CodigoEstablecimiento),
    CONSTRAINT CK_Establecimiento_Estado CHECK (Estado IN ('A','I'))
);
GO
CREATE TABLE dbo.Atencion (
    AtencionId INT IDENTITY(1,1) CONSTRAINT PK_Atencion PRIMARY KEY,
    PacienteId INT NOT NULL,
    EstablecimientoId INT NOT NULL,
    TipoAtencion VARCHAR(30) NOT NULL,
    DuracionMinutos INT NOT NULL,
    ClasificacionDuracion VARCHAR(20) NOT NULL,
    FechaAtencion DATETIME2 NOT NULL CONSTRAINT DF_Atencion_Fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_Atencion_Paciente FOREIGN KEY (PacienteId) REFERENCES dbo.Paciente(PacienteId),
    CONSTRAINT FK_Atencion_Establecimiento FOREIGN KEY (EstablecimientoId)
        REFERENCES dbo.EstablecimientoSalud(EstablecimientoId),
    CONSTRAINT CK_Atencion_Duracion CHECK (DuracionMinutos > 0),
    CONSTRAINT CK_Atencion_Tipo CHECK (TipoAtencion IN ('CONSULTA','CONTROL','VACUNACION')),
    CONSTRAINT CK_Atencion_Clasificacion CHECK (ClasificacionDuracion IN ('CORTA','REGULAR','PROLONGADA'))
);
GO
INSERT INTO dbo.Paciente(CodigoPaciente,Estado)
VALUES ('PAC-001','A'),('PAC-002','A'),('PAC-003','I');
INSERT INTO dbo.EstablecimientoSalud(CodigoEstablecimiento,Nombre,Provincia,Estado)
VALUES ('EST-001','Centro de Salud Norte','Trujillo','A'),
       ('EST-002','Puesto de Salud Esperanza','Trujillo','A'),
       ('EST-003','Centro de Salud Temporal','Trujillo','I');
GO
SELECT * FROM dbo.Paciente;
SELECT * FROM dbo.EstablecimientoSalud;
GO

DECLARE @PacienteId INT = 1;
DECLARE @EstablecimientoId INT = 1;
DECLARE @TipoAtencion VARCHAR(30) = 'CONSULTA';
DECLARE @DuracionMinutos INT = 20;
DECLARE @EstadoValidacion VARCHAR(15) = 'VALIDO';
DECLARE @Clasificacion VARCHAR(20) = NULL;
DECLARE @Mensaje VARCHAR(250) = NULL;

IF @PacienteId IS NULL OR NOT EXISTS
    (SELECT 1 FROM dbo.Paciente WHERE PacienteId = @PacienteId AND Estado = 'A')
BEGIN
    SET @EstadoValidacion = 'INVALIDO';
    SET @Mensaje = 'El paciente no existe o se encuentra inactivo.';
END
ELSE IF @EstablecimientoId IS NULL OR NOT EXISTS
    (SELECT 1 FROM dbo.EstablecimientoSalud
     WHERE EstablecimientoId = @EstablecimientoId AND Estado = 'A')
BEGIN
    SET @EstadoValidacion = 'INVALIDO';
    SET @Mensaje = 'El establecimiento no existe o esta inactivo.';
END
ELSE IF @TipoAtencion IS NULL OR LTRIM(RTRIM(@TipoAtencion)) = ''
BEGIN
    SET @EstadoValidacion = 'INVALIDO';
    SET @Mensaje = 'El tipo de atencion es obligatorio.';
END
ELSE IF @TipoAtencion NOT IN ('CONSULTA','CONTROL','VACUNACION')
BEGIN
    SET @EstadoValidacion = 'INVALIDO';
    SET @Mensaje = 'El tipo de atencion indicado no es valido.';
END
ELSE IF @DuracionMinutos IS NULL OR @DuracionMinutos <= 0
BEGIN
    SET @EstadoValidacion = 'INVALIDO';
    SET @Mensaje = 'La duracion debe ser mayor que cero.';
END
ELSE
BEGIN
    SET @Clasificacion = CASE
        WHEN @DuracionMinutos BETWEEN 1 AND 15 THEN 'CORTA'
        WHEN @DuracionMinutos BETWEEN 16 AND 30 THEN 'REGULAR'
        ELSE 'PROLONGADA'
    END;
    SET @Mensaje = 'Los datos de la atencion son validos.';
END;
SELECT @PacienteId AS PacienteId, @EstablecimientoId AS EstablecimientoId,
       @TipoAtencion AS TipoAtencion, @DuracionMinutos AS DuracionMinutos,
       @EstadoValidacion AS EstadoValidacion, @Clasificacion AS Clasificacion,
       @Mensaje AS Mensaje;
GO
   
DECLARE @Pruebas TABLE(Caso VARCHAR(22), PacienteId INT, EstablecimientoId INT,
                      TipoAtencion VARCHAR(30), DuracionMinutos INT);
INSERT INTO @Pruebas VALUES
('Caso 1',1,1,'CONSULTA',20),
('Caso 2',3,1,'CONSULTA',20),
('Caso 3',1,3,'CONSULTA',20),
('Caso 4',1,1,'CONSULTA',0),
('Caso 5',1,1,'LABORATORIO',20),
('Caso 6 (15)',1,1,'CONSULTA',15),
('Caso 6 (16)',1,1,'CONSULTA',16),
('Caso 6 (30)',1,1,'CONSULTA',30),
('Caso 6 (31)',1,1,'CONSULTA',31);
SELECT T.Caso, T.PacienteId, T.EstablecimientoId, T.TipoAtencion, T.DuracionMinutos,
 CASE WHEN T.PacienteId IS NULL OR P.PacienteId IS NULL THEN 'INVALIDO'
      WHEN T.EstablecimientoId IS NULL OR E.EstablecimientoId IS NULL THEN 'INVALIDO'
      WHEN T.TipoAtencion IS NULL OR LTRIM(RTRIM(T.TipoAtencion)) = '' THEN 'INVALIDO'
      WHEN T.TipoAtencion NOT IN ('CONSULTA','CONTROL','VACUNACION') THEN 'INVALIDO'
      WHEN T.DuracionMinutos IS NULL OR T.DuracionMinutos <= 0 THEN 'INVALIDO'
      ELSE 'VALIDO' END AS EstadoValidacion,
 CASE WHEN P.PacienteId IS NULL OR E.EstablecimientoId IS NULL
          OR T.TipoAtencion IS NULL OR T.TipoAtencion NOT IN ('CONSULTA','CONTROL','VACUNACION')
          OR T.DuracionMinutos IS NULL OR T.DuracionMinutos <= 0 THEN NULL
      WHEN T.DuracionMinutos BETWEEN 1 AND 15 THEN 'CORTA'
      WHEN T.DuracionMinutos BETWEEN 16 AND 30 THEN 'REGULAR'
      ELSE 'PROLONGADA' END AS Clasificacion
FROM @Pruebas AS T
LEFT JOIN dbo.Paciente AS P ON P.PacienteId = T.PacienteId AND P.Estado = 'A'
LEFT JOIN dbo.EstablecimientoSalud AS E ON E.EstablecimientoId = T.EstablecimientoId AND E.Estado = 'A';
GO

DECLARE @Minutos INT = 10;
WHILE @Minutos <= 40
BEGIN
    PRINT CONCAT(@Minutos, ' min -> ',
        CASE WHEN @Minutos BETWEEN 1 AND 15 THEN 'CORTA'
             WHEN @Minutos BETWEEN 16 AND 30 THEN 'REGULAR'
             ELSE 'PROLONGADA' END);
    SET @Minutos = @Minutos + 10;
END;
GO
