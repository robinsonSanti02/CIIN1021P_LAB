USE BDDataSaludTema04;
GO

SELECT AtencionId AS atencionId,
       TipoAtencion AS tipo
FROM dbo.Atencion
WHERE AtencionId = 1101
FOR JSON PATH;
GO

SELECT AtencionId AS atencionId,
       EstablecimientoId AS establecimientoId,
       FechaAtencion AS fecha,
       TipoAtencion AS tipo,
       DuracionMinutos AS duracionMinutos,
       'SQL_E04' AS origen
FROM dbo.Atencion
WHERE Lote = 'T04_DEMO'
  AND AtencionId BETWEEN 1101 AND 1104
  AND EstadoRegistro = 'VALIDO'
ORDER BY AtencionId
FOR JSON PATH;
GO

SELECT AtencionId, EstablecimientoId, FechaAtencion, TipoAtencion,
       DuracionMinutos, EstadoRegistro, Lote
FROM dbo.Atencion
WHERE Lote = 'T04_DEMO'
  AND AtencionId BETWEEN 1101 AND 1104
ORDER BY AtencionId;
GO
