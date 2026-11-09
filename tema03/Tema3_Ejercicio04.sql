USE BDDataSaludTema01;
GO

DROP TABLE IF EXISTS dbo.AtencionRendimientoTema03;
GO

CREATE TABLE dbo.AtencionRendimientoTema03(
    AtencionRendimientoId INT IDENTITY(1,1)
        CONSTRAINT PK_AtencionRendimientoTema03 PRIMARY KEY,
    EstablecimientoId INT NOT NULL,
    FechaAtencion DATETIME2 NOT NULL,
    TipoAtencion VARCHAR(30) NOT NULL,
    DuracionMinutos INT NOT NULL
);
GO

WITH Numeros AS (
    SELECT TOP (50000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Numero
    FROM sys.all_objects AS A
    CROSS JOIN sys.all_objects AS B
)
INSERT INTO dbo.AtencionRendimientoTema03
    (EstablecimientoId, FechaAtencion, TipoAtencion, DuracionMinutos)
SELECT
    ((Numero * 17) % 50) + 1,
    DATEADD(MINUTE, Numero % 1440,
        DATEADD(DAY, Numero % 365, CAST('2025-09-01' AS DATETIME2))),
    CASE Numero % 3
        WHEN 0 THEN 'CONSULTA'
        WHEN 1 THEN 'CONTROL'
        ELSE 'VACUNACION'
    END,
    ((Numero * 7) % 50) + 10
FROM Numeros;
GO

SELECT COUNT(*) AS TotalAtenciones
FROM dbo.AtencionRendimientoTema03;

EXEC sp_helpindex 'dbo.AtencionRendimientoTema03';
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT AtencionRendimientoId, EstablecimientoId, FechaAtencion
FROM dbo.AtencionRendimientoTema03
WHERE EstablecimientoId = 17
  AND FechaAtencion >= '2026-07-01'
  AND FechaAtencion < '2026-08-01';
GO

SELECT AtencionRendimientoId, FechaAtencion, TipoAtencion, DuracionMinutos
FROM dbo.AtencionRendimientoTema03
WHERE EstablecimientoId = 17
  AND FechaAtencion >= '2026-07-01'
  AND FechaAtencion < '2026-07-16';
GO

CREATE NONCLUSTERED INDEX
    IX_AtencionRendimientoTema03_Establecimiento_Fecha
ON dbo.AtencionRendimientoTema03 (EstablecimientoId, FechaAtencion);
GO

SELECT AtencionRendimientoId, EstablecimientoId, FechaAtencion
FROM dbo.AtencionRendimientoTema03
WHERE EstablecimientoId = 17
  AND FechaAtencion >= '2026-07-01'
  AND FechaAtencion < '2026-08-01';
GO

SELECT AtencionRendimientoId, FechaAtencion, TipoAtencion, DuracionMinutos
FROM dbo.AtencionRendimientoTema03
WHERE EstablecimientoId = 17
  AND FechaAtencion >= '2026-07-01'
  AND FechaAtencion < '2026-07-16';
GO

CREATE NONCLUSTERED INDEX
    IX_AtencionRendimientoTema03_Establecimiento_Fecha
ON dbo.AtencionRendimientoTema03 (EstablecimientoId, FechaAtencion)
INCLUDE (TipoAtencion, DuracionMinutos)
WITH (DROP_EXISTING = ON);
GO

SELECT AtencionRendimientoId, EstablecimientoId, FechaAtencion
FROM dbo.AtencionRendimientoTema03
WHERE EstablecimientoId = 17
  AND FechaAtencion >= '2026-07-01'
  AND FechaAtencion < '2026-08-01';
GO

SELECT AtencionRendimientoId, FechaAtencion, TipoAtencion, DuracionMinutos
FROM dbo.AtencionRendimientoTema03
WHERE EstablecimientoId = 17
  AND FechaAtencion >= '2026-07-01'
  AND FechaAtencion < '2026-07-16';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

SELECT name AS Indice, type_desc AS Tipo, is_disabled AS EstaDeshabilitado
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.AtencionRendimientoTema03')
ORDER BY index_id;
GO

SELECT Etapa, OperadorPrincipal, LecturasLogicas, Filas, KeyLookup
FROM (
    VALUES
        (1, N'A - Antes de indices', N'Clustered Index Scan', 259, 96, N'No'),
        (2, N'A - Despues de decision 1', N'Index Seek', 2, 96, N'No'),
        (3, N'B - Antes de indices', N'Clustered Index Scan', 259, 41, N'No'),
        (4, N'B - Despues de decision 1', N'Clustered Index Scan', 259, 41, N'No'),
        (5, N'B - Despues de decision 2', N'Index Seek', 2, 41, N'No'),
        (6, N'A - Despues de decision 2', N'Index Seek', 4, 96, N'No')
) AS Evidencia(Orden, Etapa, OperadorPrincipal, LecturasLogicas, Filas, KeyLookup)
ORDER BY Orden;
GO

SELECT Linea, Justificacion
FROM (
    VALUES
        (1, N'Se situo EstablecimientoId primero porque utiliza igualdad y FechaAtencion despues porque aplica un filtro por rango.'),
        (2, N'La consulta A cambio de Clustered Index Scan a Index Seek y sus lecturas logicas disminuyeron de 259 a 2 con el primer indice.'),
        (3, N'La consulta B mantuvo un Clustered Index Scan hasta incorporar TipoAtencion y DuracionMinutos mediante INCLUDE; entonces bajo de 259 a 2 lecturas.'),
        (4, N'El mismo indice puede servir para el establecimiento 25 en marzo porque el patron de filtro coincide, aunque el plan y la mejora dependen de la distribucion de los datos.')
) AS Fundamentacion(Linea, Justificacion)
ORDER BY Linea;
GO
