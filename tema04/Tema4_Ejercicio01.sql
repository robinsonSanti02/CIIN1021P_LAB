USE BDDataSaludTema04;
GO

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Atencion')
      AND name = N'IX_T04_Atencion_Establecimiento_Fecha'
)
BEGIN
    DROP INDEX IX_T04_Atencion_Establecimiento_Fecha ON dbo.Atencion;
END;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT AtencionId, EstablecimientoId, FechaAtencion
FROM dbo.Atencion
WHERE EstablecimientoId = 2
  AND FechaAtencion >= '20260901'
  AND FechaAtencion < '20261001'
ORDER BY FechaAtencion;
GO

CREATE NONCLUSTERED INDEX IX_T04_Atencion_Establecimiento_Fecha
ON dbo.Atencion(EstablecimientoId, FechaAtencion);
GO

SELECT AtencionId, EstablecimientoId, FechaAtencion
FROM dbo.Atencion
WHERE EstablecimientoId = 2
  AND FechaAtencion >= '20260901'
  AND FechaAtencion < '20261001'
ORDER BY FechaAtencion;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

SELECT name, type_desc, is_disabled
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.Atencion')
  AND name = N'IX_T04_Atencion_Establecimiento_Fecha';
GO
