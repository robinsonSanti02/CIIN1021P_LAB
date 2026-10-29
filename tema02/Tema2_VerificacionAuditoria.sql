USE BDDataSaludTema01;
GO

DECLARE @AuditoriaId BIGINT =
    (SELECT MAX(AuditoriaId) FROM dbo.AuditoriaAtencion);

SELECT A.AuditoriaId, A.AtencionId, A.Operacion, A.FechaOperacion
FROM dbo.AuditoriaAtencion AS A
WHERE A.AuditoriaId = @AuditoriaId;

SELECT V.Campo, V.Valor
FROM dbo.AuditoriaAtencion AS A
CROSS APPLY (VALUES
    (1, N'UsuarioBD', CONVERT(NVARCHAR(128), A.UsuarioBD)),
    (2, N'TerminalBD', CONVERT(NVARCHAR(128), A.TerminalBD)),
    (3, N'AplicacionBD', CONVERT(NVARCHAR(128), A.AplicacionBD))
) AS V(Orden, Campo, Valor)
WHERE A.AuditoriaId = @AuditoriaId
ORDER BY V.Orden;
GO
