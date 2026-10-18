/* TEMA 01 | EJERCICIO 05 | AMPLIACION: ejecutar despues del 04. */
USE BDDataSaludTema01;
GO
CREATE OR ALTER FUNCTION dbo.ufn_RegistrosAptosCarga(@LoteCarga VARCHAR(20))
RETURNS TABLE
AS
RETURN (
    SELECT S.RegistroId,P.PacienteId,E.EstablecimientoId,
           S.CodigoPaciente,S.CodigoEstablecimiento,S.TipoAtencion,
           S.DuracionMinutos,
           dbo.ufn_ClasificarDuracionAtencion(S.DuracionMinutos) AS ClasificacionDuracion,
           S.FechaAtencion
    FROM dbo.AtencionStaging AS S
    INNER JOIN dbo.Paciente AS P
        ON P.CodigoPaciente=S.CodigoPaciente AND P.Estado='A'
    INNER JOIN dbo.EstablecimientoSalud AS E
        ON E.CodigoEstablecimiento=S.CodigoEstablecimiento AND E.Estado='A'
    WHERE S.LoteCarga=@LoteCarga
      AND S.TipoAtencion IN ('CONSULTA','CONTROL','VACUNACION')
      AND S.DuracionMinutos BETWEEN 1 AND 180
      AND S.FechaAtencion IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM dbo.AtencionStaging AS B
          WHERE B.LoteCarga=S.LoteCarga AND B.RegistroId<S.RegistroId
            AND B.CodigoPaciente=S.CodigoPaciente
            AND B.CodigoEstablecimiento=S.CodigoEstablecimiento
            AND B.TipoAtencion=S.TipoAtencion
            AND B.DuracionMinutos=S.DuracionMinutos
            AND B.FechaAtencion=S.FechaAtencion
      )
);
GO
/* Prueba 1: una sola fila en LOTE-001. */
SELECT * FROM dbo.ufn_RegistrosAptosCarga('LOTE-001');
GO
/* Prueba 2: segundo lote, insercion protegida para no repetirla. */
IF NOT EXISTS (SELECT 1 FROM dbo.AtencionStaging WHERE LoteCarga='LOTE-002')
BEGIN
    INSERT INTO dbo.AtencionStaging
        (LoteCarga,CodigoPaciente,CodigoEstablecimiento,
         TipoAtencion,DuracionMinutos,FechaAtencion)
    VALUES
        ('LOTE-002','PAC-001','EST-001','CONTROL',10,'2026-08-20'),
        ('LOTE-002','PAC-002','EST-002','VACUNACION',25,'2026-08-20'),
        ('LOTE-002','PAC-003','EST-001','CONSULTA',15,'2026-08-20'),
        ('LOTE-002','PAC-999','EST-001','CONSULTA',20,'2026-08-20');
END;
GO
SELECT * FROM dbo.ufn_RegistrosAptosCarga('LOTE-002') ORDER BY RegistroId;
GO
/* Reflexion: los OBSERVADOS requieren revision humana; eliminarlos puede
   ocultar una atencion real, cargarlos sin validar sesga indicadores. */
