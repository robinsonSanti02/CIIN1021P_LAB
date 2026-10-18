/* TEMA 01 | EJERCICIO 04 | Ejecutar luego del 01-03.
   SOLO UNA VEZ: el INSERT del LOTE-001 contiene seis filas de ejemplo.
*/
USE BDDataSaludTema01;
GO
DROP TABLE IF EXISTS dbo.AtencionStaging;
GO
CREATE TABLE dbo.AtencionStaging(
    RegistroId INT IDENTITY(1,1) CONSTRAINT PK_AtencionStaging PRIMARY KEY,
    LoteCarga VARCHAR(20) NOT NULL,
    CodigoPaciente VARCHAR(20) NULL,
    CodigoEstablecimiento VARCHAR(20) NULL,
    TipoAtencion VARCHAR(30) NULL,
    DuracionMinutos INT NULL,
    FechaAtencion DATE NULL
);
GO
INSERT INTO dbo.AtencionStaging(LoteCarga,CodigoPaciente,CodigoEstablecimiento,
                                 TipoAtencion,DuracionMinutos,FechaAtencion)
VALUES
('LOTE-001','PAC-001','EST-001','CONSULTA',20,'2026-08-19'),
('LOTE-001',NULL,'EST-001','CONSULTA',15,'2026-08-19'),
('LOTE-001','PAC-002','EST-002','CONTROL',0,'2026-08-19'),
('LOTE-001','PAC-001','EST-001','LABORATORIO',30,'2026-08-19'),
('LOTE-001','PAC-002','EST-002','CONSULTA',240,'2026-08-19'),
('LOTE-001','PAC-001','EST-001','CONSULTA',20,'2026-08-19');
GO

/* Paso 4: un registro duplicado posterior (RegistroId = 6). */
SELECT A.RegistroId,A.CodigoPaciente,
    CASE WHEN EXISTS (
        SELECT 1 FROM dbo.AtencionStaging AS B
        WHERE B.LoteCarga = A.LoteCarga AND B.RegistroId < A.RegistroId
          AND B.CodigoPaciente=A.CodigoPaciente
          AND B.CodigoEstablecimiento=A.CodigoEstablecimiento
          AND B.TipoAtencion=A.TipoAtencion
          AND B.DuracionMinutos=A.DuracionMinutos
          AND B.FechaAtencion=A.FechaAtencion
    ) THEN 'SI' ELSE 'NO' END AS EsDuplicado
FROM dbo.AtencionStaging AS A
WHERE A.LoteCarga='LOTE-001'
ORDER BY A.RegistroId;
GO

CREATE OR ALTER PROCEDURE dbo.usp_EvaluarCalidadLote
    @LoteCarga VARCHAR(20),
    @TotalValidos INT OUTPUT,
    @TotalObservados INT OUTPUT,
    @TotalInvalidos INT OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @TotalValidos=0;
        SET @TotalObservados=0;
        SET @TotalInvalidos=0;
        SET @Mensaje=NULL;
        IF @LoteCarga IS NULL OR LTRIM(RTRIM(@LoteCarga))=''
        BEGIN
            ;THROW 50041,'El codigo del lote es obligatorio.',1;
        END;
        IF NOT EXISTS (SELECT 1 FROM dbo.AtencionStaging WHERE LoteCarga=@LoteCarga)
        BEGIN
            ;THROW 50042,'El lote indicado no contiene registros.',1;
        END;
        DECLARE @Evaluacion TABLE(
            RegistroId INT,
            Clasificacion VARCHAR(15),
            Motivo VARCHAR(200)
        );
        INSERT INTO @Evaluacion(RegistroId,Clasificacion,Motivo)
            SELECT RegistroId,NULL,NULL FROM dbo.AtencionStaging WHERE LoteCarga=@LoteCarga;

        /* Regla 1: datos obligatorios informados */
        UPDATE E
        SET E.Clasificacion='INVALIDO',E.Motivo='Campo obligatorio no informado.'
        FROM @Evaluacion AS E
        JOIN dbo.AtencionStaging AS A ON A.RegistroId=E.RegistroId
        WHERE E.Clasificacion IS NULL
          AND (A.CodigoPaciente IS NULL OR A.CodigoEstablecimiento IS NULL
               OR A.TipoAtencion IS NULL OR A.FechaAtencion IS NULL);

        /* Regla 2: duración faltante / no positiva */
        UPDATE E
        SET E.Clasificacion='INVALIDO',E.Motivo='Duracion invalida.'
        FROM @Evaluacion AS E
        JOIN dbo.AtencionStaging AS A ON A.RegistroId=E.RegistroId
        WHERE E.Clasificacion IS NULL
          AND (A.DuracionMinutos IS NULL OR A.DuracionMinutos<=0);

        /* Regla 3: tipo ajeno a la lista */
        UPDATE E
        SET E.Clasificacion='INVALIDO',E.Motivo='Tipo de atencion no permitido.'
        FROM @Evaluacion AS E
        JOIN dbo.AtencionStaging AS A ON A.RegistroId=E.RegistroId
        WHERE E.Clasificacion IS NULL
          AND A.TipoAtencion NOT IN ('CONSULTA','CONTROL','VACUNACION');

        /* Regla 4: segunda ocurrencia en adelante */
        UPDATE E
        SET E.Clasificacion='INVALIDO',E.Motivo='Posible registro duplicado.'
        FROM @Evaluacion AS E
        JOIN dbo.AtencionStaging AS A ON A.RegistroId=E.RegistroId
        WHERE E.Clasificacion IS NULL
          AND EXISTS (
            SELECT 1 FROM dbo.AtencionStaging AS B
            WHERE B.LoteCarga=A.LoteCarga AND B.RegistroId<A.RegistroId
              AND B.CodigoPaciente=A.CodigoPaciente
              AND B.CodigoEstablecimiento=A.CodigoEstablecimiento
              AND B.TipoAtencion=A.TipoAtencion
              AND B.DuracionMinutos=A.DuracionMinutos
              AND B.FechaAtencion=A.FechaAtencion
          );

        /* Regla 5: potencial valor atipico, no se borra */
        UPDATE E
        SET E.Clasificacion='OBSERVADO',E.Motivo='Duracion mayor a 180 minutos.'
        FROM @Evaluacion AS E
        JOIN dbo.AtencionStaging AS A ON A.RegistroId=E.RegistroId
        WHERE E.Clasificacion IS NULL AND A.DuracionMinutos>180;

        /* Regla 6: todo lo restante cumple los criterios del lote */
        UPDATE @Evaluacion
        SET Clasificacion='VALIDO',Motivo='Cumple las reglas.'
        WHERE Clasificacion IS NULL;

        SELECT @TotalValidos=SUM(CASE WHEN Clasificacion='VALIDO' THEN 1 ELSE 0 END),
               @TotalObservados=SUM(CASE WHEN Clasificacion='OBSERVADO' THEN 1 ELSE 0 END),
               @TotalInvalidos=SUM(CASE WHEN Clasificacion='INVALIDO' THEN 1 ELSE 0 END)
        FROM @Evaluacion;

        /* Tabla 1: detalle por registro */
        SELECT A.RegistroId,A.CodigoPaciente,A.CodigoEstablecimiento,A.TipoAtencion,
               A.DuracionMinutos,A.FechaAtencion,E.Clasificacion,E.Motivo
        FROM dbo.AtencionStaging AS A
        INNER JOIN @Evaluacion AS E ON E.RegistroId=A.RegistroId
        WHERE A.LoteCarga=@LoteCarga
        ORDER BY A.RegistroId;

        /* Tabla 2: motivos y numeros de casos (contiene 'Cumple las reglas'). */
        SELECT E.Motivo AS ProblemaDeCalidad,COUNT(*) AS RegistrosAfectados
        FROM @Evaluacion AS E
        GROUP BY E.Motivo
        ORDER BY COUNT(*) DESC,E.Motivo;
        SET @Mensaje=CONCAT('Evaluacion completada. Validos: ',@TotalValidos,
                            ', observados: ',@TotalObservados,
                            ', invalidos: ',@TotalInvalidos,'.');
    END TRY
    BEGIN CATCH
        SET @Mensaje=CONCAT('Error ',ERROR_NUMBER(),': ',ERROR_MESSAGE());
        THROW;
    END CATCH;
END;
GO

DECLARE @V INT,@O INT,@I INT,@M VARCHAR(300);
EXEC dbo.usp_EvaluarCalidadLote 'LOTE-001',@V OUTPUT,@O OUTPUT,@I OUTPUT,@M OUTPUT;
SELECT @V AS Validos,@O AS Observados,@I AS Invalidos,@M AS Mensaje;
GO
