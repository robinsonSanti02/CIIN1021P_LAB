USE BDDataSaludTema05;
GO

SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    DELETE FROM stg.AtencionValida;
    DELETE FROM stg.AtencionRechazada;
    DELETE FROM stg.Atencion;

    INSERT INTO stg.Atencion (Origen, CodigoAtencion, FechaAtencion, CodigoEstablecimiento,
                              TipoAtencion, DuracionMinutos, EstadoRegistro, CodigoPaciente)
    SELECT 'HIS', CodigoAtencion, FechaAtencion, CodigoEstablecimiento,
           TipoAtencion, DuracionMinutos, EstadoRegistro, CodigoPaciente
    FROM src.AtencionHIS
    UNION ALL
    SELECT 'CAMPANIA', CodigoAtencion, FechaAtencion, CodigoEstablecimiento,
           TipoAtencion, DuracionMinutos, EstadoRegistro, CodigoPaciente
    FROM src.AtencionCampania;

    IF OBJECT_ID('tempdb..#ClasificacionT05') IS NOT NULL DROP TABLE #ClasificacionT05;

    WITH Textos AS (
        SELECT a.*,
               UPPER(LTRIM(RTRIM(COALESCE(a.CodigoEstablecimiento, '')))) AS EstLimpio,
               UPPER(LTRIM(RTRIM(COALESCE(a.TipoAtencion, '')))) AS TipoLimpio,
               UPPER(LTRIM(RTRIM(COALESCE(a.EstadoRegistro, '')))) AS EstadoLimpio
        FROM stg.Atencion AS a
    ),
    Homologados AS (
        SELECT t.*,
               CASE TipoLimpio WHEN 'VACUNA' THEN 'VACUNACION' WHEN 'CTRL' THEN 'CONTROL'
                    ELSE TipoLimpio END AS TipoNormalizado,
               CASE EstadoLimpio WHEN 'V' THEN 'VALIDO' ELSE EstadoLimpio END AS EstadoNormalizado
        FROM Textos AS t
    )
    SELECT h.*,
           CASE WHEN FechaAtencion IS NULL THEN 'FECHA_AUSENTE'
                WHEN EstLimpio = '' THEN 'ESTABLECIMIENTO_AUSENTE'
                WHEN TipoNormalizado = '' THEN 'TIPO_AUSENTE'
                WHEN DuracionMinutos IS NULL THEN 'DURACION_AUSENTE'
                WHEN DuracionMinutos <= 0 THEN 'DURACION_NO_POSITIVA'
                WHEN EstadoNormalizado <> 'VALIDO' THEN 'ESTADO_NO_VALIDO'
                ELSE '' END AS MotivoRechazo
    INTO #ClasificacionT05
    FROM Homologados AS h;

    INSERT INTO stg.AtencionValida
        (Origen, CodigoAtencion, FechaAtencion, CodigoEstablecimiento, TipoAtencion,
         DuracionMinutos, EstadoRegistro, CodigoPaciente)
    SELECT Origen, CodigoAtencion, FechaAtencion, EstLimpio, TipoNormalizado,
           DuracionMinutos, EstadoNormalizado, CodigoPaciente
    FROM #ClasificacionT05
    WHERE MotivoRechazo = '';

    INSERT INTO stg.AtencionRechazada
        (Origen, CodigoAtencion, FechaAtencion, CodigoEstablecimiento, TipoAtencion,
         DuracionMinutos, EstadoRegistro, CodigoPaciente, MotivoRechazo)
    SELECT Origen, CodigoAtencion, FechaAtencion, CodigoEstablecimiento, TipoAtencion,
           DuracionMinutos, EstadoRegistro, CodigoPaciente, MotivoRechazo
    FROM #ClasificacionT05
    WHERE MotivoRechazo <> '';

    DROP TABLE #ClasificacionT05;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT (SELECT COUNT(*) FROM stg.Atencion) AS Staging,
       (SELECT COUNT(*) FROM stg.AtencionValida) AS Validas,
       (SELECT COUNT(*) FROM stg.AtencionRechazada) AS Rechazadas,
       (SELECT SUM(DuracionMinutos) FROM stg.AtencionValida) AS MinutosValidos;

SELECT Origen, CodigoAtencion, CodigoEstablecimiento, TipoAtencion, EstadoRegistro
FROM stg.AtencionValida ORDER BY Origen, CodigoAtencion;

SELECT Origen, CodigoAtencion, MotivoRechazo
FROM stg.AtencionRechazada ORDER BY Origen, CodigoAtencion;
GO
