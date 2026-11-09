USE BDDataSaludTema01;
GO

CREATE OR ALTER FUNCTION dbo.ufn_RutaRespaldo()
RETURNS NVARCHAR(260)
AS
BEGIN
    DECLARE @Ruta NVARCHAR(260) = CONVERT(
        NVARCHAR(260),
        COALESCE(
            SERVERPROPERTY('InstanceDefaultBackupPath'),
            SERVERPROPERTY('InstanceDefaultDataPath')
        )
    );

    IF RIGHT(@Ruta, 1) NOT IN ('\', '/')
    BEGIN
        SET @Ruta = @Ruta + N'\';
    END;

    RETURN @Ruta;
END;
GO

SELECT
    dbo.ufn_RutaRespaldo() AS RutaRespaldo,
    SERVERPROPERTY('InstanceDefaultDataPath') AS RutaDatos;
GO

DROP TABLE IF EXISTS dbo.EvidenciaBackupTema03;
GO

CREATE TABLE dbo.EvidenciaBackupTema03(
    EvidenciaId INT IDENTITY(1,1)
        CONSTRAINT PK_EvidenciaBackupTema03 PRIMARY KEY,
    Descripcion VARCHAR(100) NOT NULL,
    FechaRegistro DATETIME2 NOT NULL
        CONSTRAINT DF_EvidenciaBackup_Fecha DEFAULT (SYSDATETIME())
);
GO

INSERT INTO dbo.EvidenciaBackupTema03 (Descripcion)
VALUES ('1. Antes del FULL');
GO

DECLARE @ArchivoFull NVARCHAR(400) =
    dbo.ufn_RutaRespaldo() + N'BDDataSaludTema03_FULL.bak';

BACKUP DATABASE BDDataSaludTema01
TO DISK = @ArchivoFull
WITH INIT, CHECKSUM, NAME = N'DataSalud Tema 03 - FULL', STATS = 25;

SELECT @ArchivoFull AS ArchivoGenerado;
GO

INSERT INTO dbo.EvidenciaBackupTema03 (Descripcion)
VALUES ('2. Despues del FULL');
GO

DECLARE @ArchivoDiff NVARCHAR(400) =
    dbo.ufn_RutaRespaldo() + N'BDDataSaludTema03_DIFF.bak';

BACKUP DATABASE BDDataSaludTema01
TO DISK = @ArchivoDiff
WITH DIFFERENTIAL, INIT, CHECKSUM,
    NAME = N'DataSalud Tema 03 - DIFF', STATS = 25;

SELECT @ArchivoDiff AS ArchivoGenerado;
GO

INSERT INTO dbo.EvidenciaBackupTema03 (Descripcion)
VALUES ('3. Despues del DIFF');
GO

DECLARE @ArchivoFull NVARCHAR(400) =
    dbo.ufn_RutaRespaldo() + N'BDDataSaludTema03_FULL.bak';
DECLARE @ArchivoDiff NVARCHAR(400) =
    dbo.ufn_RutaRespaldo() + N'BDDataSaludTema03_DIFF.bak';

RESTORE VERIFYONLY FROM DISK = @ArchivoFull WITH CHECKSUM;
RESTORE VERIFYONLY FROM DISK = @ArchivoDiff WITH CHECKSUM;
RESTORE FILELISTONLY FROM DISK = @ArchivoFull;
GO

SELECT TOP (4)
    bs.name AS Respaldo,
    CASE bs.type
        WHEN 'D' THEN 'FULL'
        WHEN 'I' THEN 'DIFFERENTIAL'
        WHEN 'L' THEN 'LOG'
    END AS Tipo,
    bs.backup_finish_date AS Fin,
    mf.physical_device_name AS Archivo
FROM msdb.dbo.backupset AS bs
INNER JOIN msdb.dbo.backupmediafamily AS mf
    ON mf.media_set_id = bs.media_set_id
WHERE bs.database_name = 'BDDataSaludTema01'
ORDER BY bs.backup_finish_date DESC;
GO

USE master;
GO

IF DB_ID('BDDataSaludTema03_Restore') IS NOT NULL
BEGIN
    IF DATABASEPROPERTYEX('BDDataSaludTema03_Restore', 'Status') = 'ONLINE'
    BEGIN
        ALTER DATABASE BDDataSaludTema03_Restore
            SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    END;
    DROP DATABASE BDDataSaludTema03_Restore;
END;
GO

DECLARE @Ruta NVARCHAR(260) =
    BDDataSaludTema01.dbo.ufn_RutaRespaldo();
DECLARE @ArchivoFull NVARCHAR(400) =
    @Ruta + N'BDDataSaludTema03_FULL.bak';
DECLARE @ArchivoDiff NVARCHAR(400) =
    @Ruta + N'BDDataSaludTema03_DIFF.bak';
DECLARE @RutaDatos NVARCHAR(260) = CONVERT(
    NVARCHAR(260), SERVERPROPERTY('InstanceDefaultDataPath')
);

IF RIGHT(@RutaDatos, 1) NOT IN ('\', '/')
BEGIN
    SET @RutaDatos = @RutaDatos + N'\';
END;

DECLARE @Mdf NVARCHAR(400) =
    @RutaDatos + N'BDDataSaludTema03_Restore.mdf';
DECLARE @Ldf NVARCHAR(400) =
    @RutaDatos + N'BDDataSaludTema03_Restore_log.ldf';
DECLARE @LogicoDatos SYSNAME;
DECLARE @LogicoLog SYSNAME;

SELECT @LogicoDatos = name
FROM BDDataSaludTema01.sys.database_files
WHERE type_desc = 'ROWS';

SELECT @LogicoLog = name
FROM BDDataSaludTema01.sys.database_files
WHERE type_desc = 'LOG';

RESTORE DATABASE BDDataSaludTema03_Restore
FROM DISK = @ArchivoFull
WITH MOVE @LogicoDatos TO @Mdf,
    MOVE @LogicoLog TO @Ldf,
    NORECOVERY,
    STATS = 25;

RESTORE DATABASE BDDataSaludTema03_Restore
FROM DISK = @ArchivoDiff
WITH RECOVERY, STATS = 25;
GO

SELECT 'Original' AS Base, EvidenciaId, Descripcion
FROM BDDataSaludTema01.dbo.EvidenciaBackupTema03
UNION ALL
SELECT 'Restaurada', EvidenciaId, Descripcion
FROM BDDataSaludTema03_Restore.dbo.EvidenciaBackupTema03
ORDER BY Base, EvidenciaId;
GO

USE BDDataSaludTema01;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RespaldoProgramado
    @TipoForzado VARCHAR(4) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Tipo VARCHAR(4) = @TipoForzado;
    DECLARE @Archivo NVARCHAR(400);

    IF @Tipo IS NULL
    BEGIN
        SET @Tipo = CASE
            WHEN DATEDIFF(DAY, '19000107', SYSDATETIME()) % 7 = 0
            THEN 'FULL'
            ELSE 'DIFF'
        END;
    END;

    IF @Tipo NOT IN ('FULL', 'DIFF')
    BEGIN
        ;THROW 58001, 'Tipo de respaldo no valido. Use FULL o DIFF.', 1;
    END;

    SET @Archivo = dbo.ufn_RutaRespaldo()
        + N'BDDataSalud_'
        + @Tipo
        + N'_'
        + CONVERT(NCHAR(8), SYSDATETIME(), 112)
        + N'.bak';

    IF @Tipo = 'FULL'
    BEGIN
        BACKUP DATABASE BDDataSaludTema01
        TO DISK = @Archivo
        WITH INIT, CHECKSUM;
    END
    ELSE
    BEGIN
        BACKUP DATABASE BDDataSaludTema01
        TO DISK = @Archivo
        WITH DIFFERENTIAL, INIT, CHECKSUM;
    END;

    SELECT @Tipo AS TipoRespaldo, @Archivo AS Archivo;
END;
GO

EXEC dbo.usp_RespaldoProgramado;

EXEC dbo.usp_RespaldoProgramado @TipoForzado = 'FULL';

BEGIN TRY
    EXEC dbo.usp_RespaldoProgramado @TipoForzado = 'LOG';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO

SELECT EvidenciaId, Descripcion, FechaRegistro
FROM dbo.EvidenciaBackupTema03
ORDER BY EvidenciaId;
GO
