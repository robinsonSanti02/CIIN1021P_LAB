USE BDDataSaludTema04;
GO

SELECT AtencionId, TipoAtencion, EstadoRegistro
FROM dbo.Atencion
WHERE Lote = 'T04_DEMO'
  AND AtencionId BETWEEN 1105 AND 1108
ORDER BY AtencionId;
GO
