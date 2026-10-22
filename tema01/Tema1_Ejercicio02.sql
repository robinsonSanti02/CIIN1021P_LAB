--TEMA 01 / EJERCICIO 2
USE BDDataSaludTema01;
GO
CREATE OR ALTER FUNCTION dbo.ufn_ClasificarDuracionAtencion(@Minutos INT)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @Clasificacion VARCHAR(20);
    IF @Minutos IS NULL OR @Minutos <= 0
    BEGIN
        RETURN NULL;
    END;
    SET @Clasificacion = CASE
        WHEN @Minutos BETWEEN 1 AND 15 THEN 'CORTA'
        WHEN @Minutos BETWEEN 16 AND 30 THEN 'REGULAR'
        ELSE 'PROLONGADA'
    END;
    RETURN @Clasificacion;
END;
GO
SELECT dbo.ufn_ClasificarDuracionAtencion(10) AS Caso1,
       dbo.ufn_ClasificarDuracionAtencion(15) AS Caso2,
       dbo.ufn_ClasificarDuracionAtencion(16) AS Caso3,
       dbo.ufn_ClasificarDuracionAtencion(30) AS Caso4,
       dbo.ufn_ClasificarDuracionAtencion(31) AS Caso5,
       dbo.ufn_ClasificarDuracionAtencion(0) AS Caso6;
GO
SELECT V.Minutos,
       dbo.ufn_ClasificarDuracionAtencion(V.Minutos) AS Clasificacion
FROM (VALUES (5),(15),(16),(25),(30),(31),(60)) AS V(Minutos);
GO
