/* TEMA 01 | EJERCICIO 03 | Ejecutar despues de 01 y 02.
   El procedimiento valida e inserta; el llamador controla los errores esperados.
*/
USE BDDataSaludTema01;
GO
CREATE OR ALTER PROCEDURE dbo.usp_RegistrarAtencion
    @PacienteId INT,
    @EstablecimientoId INT,
    @TipoAtencion VARCHAR(30),
    @DuracionMinutos INT,
    @AtencionId INT OUTPUT,
    @Clasificacion VARCHAR(20) OUTPUT,
    @Mensaje VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @AtencionId = NULL;
        SET @Clasificacion = NULL;
        SET @Mensaje = NULL;

        IF @PacienteId IS NULL
        BEGIN
            ;THROW 50031, 'El identificador del paciente es obligatorio.', 1;
        END;
        IF NOT EXISTS (SELECT 1 FROM dbo.Paciente WHERE PacienteId = @PacienteId)
        BEGIN
            ;THROW 50032, 'El paciente indicado no existe.', 1;
        END;
        IF NOT EXISTS (SELECT 1 FROM dbo.Paciente
                       WHERE PacienteId = @PacienteId AND Estado = 'A')
        BEGIN
            ;THROW 50033, 'El paciente se encuentra inactivo.', 1;
        END;

        IF @EstablecimientoId IS NULL
        BEGIN
            ;THROW 50034, 'El identificador del establecimiento es obligatorio.', 1;
        END;
        IF NOT EXISTS (SELECT 1 FROM dbo.EstablecimientoSalud
                       WHERE EstablecimientoId = @EstablecimientoId)
        BEGIN
            ;THROW 50035, 'El establecimiento indicado no existe.', 1;
        END;
        IF NOT EXISTS (SELECT 1 FROM dbo.EstablecimientoSalud
                       WHERE EstablecimientoId = @EstablecimientoId AND Estado = 'A')
        BEGIN
            ;THROW 50036, 'El establecimiento se encuentra inactivo.', 1;
        END;

        IF @TipoAtencion IS NULL OR LTRIM(RTRIM(@TipoAtencion)) = ''
        BEGIN
            ;THROW 50037, 'El tipo de atencion es obligatorio.', 1;
        END;
        IF @TipoAtencion NOT IN ('CONSULTA','CONTROL','VACUNACION')
        BEGIN
            ;THROW 50038, 'El tipo de atencion indicado no es valido.', 1;
        END;
        IF @DuracionMinutos IS NULL OR @DuracionMinutos <= 0
        BEGIN
            ;THROW 50039, 'La duracion debe ser mayor que cero.', 1;
        END;

        SET @Clasificacion = dbo.ufn_ClasificarDuracionAtencion(@DuracionMinutos);
        IF @Clasificacion IS NULL
        BEGIN
            ;THROW 50040, 'No fue posible clasificar la duracion.', 1;
        END;

        INSERT INTO dbo.Atencion(PacienteId,EstablecimientoId,TipoAtencion,
                                 DuracionMinutos,ClasificacionDuracion)
        VALUES(@PacienteId,@EstablecimientoId,@TipoAtencion,
               @DuracionMinutos,@Clasificacion);
        SET @AtencionId = CONVERT(INT, SCOPE_IDENTITY());
        SET @Mensaje = CONCAT('Atencion registrada correctamente. Codigo: ', @AtencionId, '.');
    END TRY
    BEGIN CATCH
        SET @Mensaje = CONCAT('Error ',ERROR_NUMBER(), ' en ',
                    COALESCE(ERROR_PROCEDURE(),'dbo.usp_RegistrarAtencion'),
                    ', linea ',ERROR_LINE(),': ',ERROR_MESSAGE());
        THROW;
    END CATCH;
END;
GO

/* Caso 1: primera insercion: AtencionId 1, REGULAR. */
DECLARE @A INT,@C VARCHAR(20),@M VARCHAR(300);
EXEC dbo.usp_RegistrarAtencion
    @PacienteId=1,@EstablecimientoId=1,@TipoAtencion='CONSULTA',@DuracionMinutos=20,
    @AtencionId=@A OUTPUT,@Clasificacion=@C OUTPUT,@Mensaje=@M OUTPUT;
SELECT @A AS AtencionId,@C AS Clasificacion,@M AS Mensaje;
GO

/* Casos 2 y 3, ambos se insertan una sola vez. */
DECLARE @A INT,@C VARCHAR(20),@M VARCHAR(300);
EXEC dbo.usp_RegistrarAtencion 2,2,'CONTROL',12,@A OUTPUT,@C OUTPUT,@M OUTPUT;
SELECT @A AS AtencionId,@C AS Clasificacion,@M AS Mensaje;
GO
DECLARE @A INT,@C VARCHAR(20),@M VARCHAR(300);
EXEC dbo.usp_RegistrarAtencion 1,2,'VACUNACION',45,@A OUTPUT,@C OUTPUT,@M OUTPUT;
SELECT @A AS AtencionId,@C AS Clasificacion,@M AS Mensaje;
GO

/* Casos 4-8. Mismo panel TRY/CATCH de la guia; cada bloque se puede ejecutar
   por separado para capturar el error sin insertar nuevas atenciones. */

/* 4. Paciente inactivo. Error esperado 50033. */
DECLARE @p INT=3, @e INT=1, @t VARCHAR(30)='CONSULTA', @d INT=20;
DECLARE @A INT, @C VARCHAR(20), @M VARCHAR(300);
BEGIN TRY
    EXEC dbo.usp_RegistrarAtencion
        @PacienteId=@p, @EstablecimientoId=@e,
        @TipoAtencion=@t, @DuracionMinutos=@d,
        @AtencionId=@A OUTPUT, @Clasificacion=@C OUTPUT, @Mensaje=@M OUTPUT;
    SELECT @A AS AtencionId, @C AS Clasificacion, @M AS Mensaje;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO

/* 5. Paciente inexistente. Error esperado 50032. */
DECLARE @p INT=999, @e INT=1, @t VARCHAR(30)='CONSULTA', @d INT=20;
DECLARE @A INT, @C VARCHAR(20), @M VARCHAR(300);
BEGIN TRY
    EXEC dbo.usp_RegistrarAtencion
        @PacienteId=@p, @EstablecimientoId=@e,
        @TipoAtencion=@t, @DuracionMinutos=@d,
        @AtencionId=@A OUTPUT, @Clasificacion=@C OUTPUT, @Mensaje=@M OUTPUT;
    SELECT @A AS AtencionId, @C AS Clasificacion, @M AS Mensaje;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO

/* 6. Establecimiento inactivo. Error esperado 50036. */
DECLARE @p INT=1, @e INT=3, @t VARCHAR(30)='CONSULTA', @d INT=20;
DECLARE @A INT, @C VARCHAR(20), @M VARCHAR(300);
BEGIN TRY
    EXEC dbo.usp_RegistrarAtencion
        @PacienteId=@p, @EstablecimientoId=@e,
        @TipoAtencion=@t, @DuracionMinutos=@d,
        @AtencionId=@A OUTPUT, @Clasificacion=@C OUTPUT, @Mensaje=@M OUTPUT;
    SELECT @A AS AtencionId, @C AS Clasificacion, @M AS Mensaje;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO

/* 7. Tipo no permitido. Error esperado 50038. */
DECLARE @p INT=1, @e INT=1, @t VARCHAR(30)='LABORATORIO', @d INT=20;
DECLARE @A INT, @C VARCHAR(20), @M VARCHAR(300);
BEGIN TRY
    EXEC dbo.usp_RegistrarAtencion
        @PacienteId=@p, @EstablecimientoId=@e,
        @TipoAtencion=@t, @DuracionMinutos=@d,
        @AtencionId=@A OUTPUT, @Clasificacion=@C OUTPUT, @Mensaje=@M OUTPUT;
    SELECT @A AS AtencionId, @C AS Clasificacion, @M AS Mensaje;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO

/* 8. Duracion invalida. Error esperado 50039. */
DECLARE @p INT=1, @e INT=1, @t VARCHAR(30)='CONSULTA', @d INT=0;
DECLARE @A INT, @C VARCHAR(20), @M VARCHAR(300);
BEGIN TRY
    EXEC dbo.usp_RegistrarAtencion
        @PacienteId=@p, @EstablecimientoId=@e,
        @TipoAtencion=@t, @DuracionMinutos=@d,
        @AtencionId=@A OUTPUT, @Clasificacion=@C OUTPUT, @Mensaje=@M OUTPUT;
    SELECT @A AS AtencionId, @C AS Clasificacion, @M AS Mensaje;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO

/* Evidencia: deben existir EXACTAMENTE tres atenciones al ejecutar una vez. */
SELECT A.AtencionId,P.CodigoPaciente,E.CodigoEstablecimiento,
       A.TipoAtencion,A.DuracionMinutos,A.ClasificacionDuracion,A.FechaAtencion
FROM dbo.Atencion A
INNER JOIN dbo.Paciente P ON P.PacienteId = A.PacienteId
INNER JOIN dbo.EstablecimientoSalud E ON E.EstablecimientoId = A.EstablecimientoId
ORDER BY A.AtencionId;
GO
