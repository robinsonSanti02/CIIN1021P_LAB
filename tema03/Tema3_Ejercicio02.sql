USE BDDataSaludTema01;
GO

IF IS_ROLEMEMBER('rol_lectura_general', 'usuario_analista') = 1
    ALTER ROLE rol_lectura_general DROP MEMBER usuario_analista;
IF IS_ROLEMEMBER('rol_analista', 'usuario_analista') = 1
    ALTER ROLE rol_analista DROP MEMBER usuario_analista;
IF IS_ROLEMEMBER('rol_auditor', 'usuario_auditor') = 1
    ALTER ROLE rol_auditor DROP MEMBER usuario_auditor;
IF IS_ROLEMEMBER('rol_administrador', 'usuario_administrador') = 1
    ALTER ROLE rol_administrador DROP MEMBER usuario_administrador;
GO

DROP USER IF EXISTS usuario_analista;
DROP USER IF EXISTS usuario_auditor;
DROP USER IF EXISTS usuario_administrador;
DROP ROLE IF EXISTS rol_lectura_general;
DROP ROLE IF EXISTS rol_analista;
DROP ROLE IF EXISTS rol_auditor;
DROP ROLE IF EXISTS rol_administrador;
GO

IF SUSER_ID('login_analista') IS NOT NULL
    DROP LOGIN login_analista;
IF SUSER_ID('login_auditor') IS NOT NULL
    DROP LOGIN login_auditor;
IF SUSER_ID('login_administrador') IS NOT NULL
    DROP LOGIN login_administrador;
GO

DECLARE @Clave NVARCHAR(60);
DECLARE @SQL NVARCHAR(MAX);

SET @Clave = N'Ds#A9' + CONVERT(NVARCHAR(32), CRYPT_GEN_RANDOM(16), 2);
SET @SQL = N'CREATE LOGIN login_analista WITH PASSWORD = '
    + QUOTENAME(@Clave, '''') + N', CHECK_POLICY = ON;';
EXEC sys.sp_executesql @SQL;

SET @Clave = N'Ds#A9' + CONVERT(NVARCHAR(32), CRYPT_GEN_RANDOM(16), 2);
SET @SQL = N'CREATE LOGIN login_auditor WITH PASSWORD = '
    + QUOTENAME(@Clave, '''') + N', CHECK_POLICY = ON;';
EXEC sys.sp_executesql @SQL;

SET @Clave = N'Ds#A9' + CONVERT(NVARCHAR(32), CRYPT_GEN_RANDOM(16), 2);
SET @SQL = N'CREATE LOGIN login_administrador WITH PASSWORD = '
    + QUOTENAME(@Clave, '''') + N', CHECK_POLICY = ON;';
EXEC sys.sp_executesql @SQL;
GO

CREATE USER usuario_analista FOR LOGIN login_analista;
CREATE USER usuario_auditor FOR LOGIN login_auditor;
CREATE USER usuario_administrador FOR LOGIN login_administrador;
GO

SELECT name AS LoginServidor, type_desc
FROM sys.server_principals
WHERE name LIKE 'login[_]%'
ORDER BY name;

SELECT name AS UsuarioBase, type_desc
FROM sys.database_principals
WHERE name LIKE 'usuario[_]%'
ORDER BY name;
GO

CREATE ROLE rol_analista;
CREATE ROLE rol_auditor;
CREATE ROLE rol_administrador;
GO

ALTER ROLE rol_analista ADD MEMBER usuario_analista;
ALTER ROLE rol_auditor ADD MEMBER usuario_auditor;
ALTER ROLE rol_administrador ADD MEMBER usuario_administrador;
GO

GRANT SELECT ON dbo.Atencion TO rol_analista;
GRANT SELECT ON dbo.Atencion TO rol_auditor;
GRANT SELECT ON dbo.AuditoriaAtencion TO rol_auditor;
DENY INSERT, UPDATE, DELETE ON dbo.Atencion TO rol_auditor;

GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Atencion TO rol_administrador;
GRANT SELECT ON dbo.AuditoriaAtencion TO rol_administrador;
GRANT SELECT ON dbo.StockVacuna TO rol_administrador;
GRANT EXECUTE ON dbo.usp_DispensarVacuna TO rol_administrador;
GO

SELECT r.name AS Rol, u.name AS Usuario
FROM sys.database_role_members AS rm
INNER JOIN sys.database_principals AS r
    ON rm.role_principal_id = r.principal_id
INNER JOIN sys.database_principals AS u
    ON rm.member_principal_id = u.principal_id
WHERE r.name IN ('rol_analista', 'rol_auditor', 'rol_administrador')
ORDER BY r.name;

SELECT pr.name AS Rol, pe.state_desc AS Estado,
       pe.permission_name AS Permiso, OBJECT_NAME(pe.major_id) AS Objeto
FROM sys.database_permissions AS pe
INNER JOIN sys.database_principals AS pr
    ON pr.principal_id = pe.grantee_principal_id
WHERE pr.name IN ('rol_analista', 'rol_auditor', 'rol_administrador')
ORDER BY Rol, Objeto, Permiso;
GO

EXECUTE AS LOGIN = 'login_analista';
SELECT SUSER_SNAME() AS LoginActual, USER_NAME() AS UsuarioActual;
SELECT TOP (3) AtencionId, TipoAtencion, DuracionMinutos
FROM dbo.Atencion
ORDER BY AtencionId;
BEGIN TRY
    DELETE FROM dbo.Atencion WHERE AtencionId = -1;
END TRY
BEGIN CATCH
    SELECT 'analista: DELETE' AS Prueba, ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
REVERT;
GO

EXECUTE AS LOGIN = 'login_auditor';
SELECT COUNT(*) AS FilasAuditoriaVisibles FROM dbo.AuditoriaAtencion;
BEGIN TRY
    UPDATE dbo.Atencion SET DuracionMinutos = 99 WHERE AtencionId = -1;
END TRY
BEGIN CATCH
    SELECT 'auditor: UPDATE' AS Prueba, ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
REVERT;
GO

SELECT SUSER_SNAME() AS DebeSerTuLogin;
GO

CREATE ROLE rol_lectura_general;
GRANT SELECT ON SCHEMA::dbo TO rol_lectura_general;
ALTER ROLE rol_lectura_general ADD MEMBER usuario_analista;
GO

EXECUTE AS LOGIN = 'login_analista';
SELECT COUNT(*) AS AuditoriaLeidaPorAnalista FROM dbo.AuditoriaAtencion;
REVERT;
GO

DENY SELECT ON dbo.AuditoriaAtencion TO rol_analista;
GO

EXECUTE AS LOGIN = 'login_analista';
BEGIN TRY
    SELECT COUNT(*) AS AuditoriaLeidaPorAnalista
    FROM dbo.AuditoriaAtencion;
END TRY
BEGIN CATCH
    SELECT 'con DENY' AS Prueba, ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
REVERT;
GO

REVOKE SELECT ON dbo.AuditoriaAtencion FROM rol_analista;
GO

EXECUTE AS LOGIN = 'login_analista';
SELECT COUNT(*) AS AuditoriaLeidaPorAnalista FROM dbo.AuditoriaAtencion;
REVERT;
GO

ALTER ROLE rol_lectura_general DROP MEMBER usuario_analista;
DROP ROLE rol_lectura_general;
DENY SELECT ON dbo.AuditoriaAtencion TO rol_analista;
GO

SELECT pr.name AS Rol, pe.state_desc AS Estado,
       pe.permission_name AS Permiso, OBJECT_NAME(pe.major_id) AS Objeto
FROM sys.database_permissions AS pe
INNER JOIN sys.database_principals AS pr
    ON pr.principal_id = pe.grantee_principal_id
WHERE pr.name = 'rol_analista'
ORDER BY Objeto, Permiso;
GO

EXECUTE AS LOGIN = 'login_administrador';
BEGIN TRY
    UPDATE dbo.StockVacuna SET Stock = Stock + 100 WHERE EstablecimientoId = 2;
END TRY
BEGIN CATCH
    SELECT 'UPDATE directo' AS Intento, ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;

BEGIN TRY
    EXEC dbo.usp_DispensarVacuna
        @PacienteId = 2,
        @EstablecimientoId = 2,
        @Vacuna = 'INFLUENZA',
        @Dosis = 1;
END TRY
BEGIN CATCH
    SELECT 'Dispensacion mediante procedimiento' AS Prueba,
           ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
REVERT;
GO

SELECT TOP (1) DispensacionId, Dosis, UsuarioBD
FROM dbo.DispensacionVacuna
ORDER BY DispensacionId DESC;

SELECT TOP (1) AuditoriaId, Operacion, UsuarioBD
FROM dbo.AuditoriaAtencion
ORDER BY AuditoriaId DESC;

SELECT SUSER_SNAME() AS LoginActual;
GO

SELECT pr.name AS Rol, pe.state_desc AS Estado,
       pe.permission_name AS Permiso, OBJECT_NAME(pe.major_id) AS Objeto,
       COL_NAME(pe.major_id, pe.minor_id) AS Columna
FROM sys.database_permissions AS pe
INNER JOIN sys.database_principals AS pr
    ON pr.principal_id = pe.grantee_principal_id
WHERE pr.name LIKE 'rol[_]%'
ORDER BY Rol, Objeto, Permiso;
GO
