USE BDDataSaludTema01;
GO

DELETE FROM dbo.AtencionStaging
WHERE LoteCarga = 'LOTE-006';
GO

INSERT INTO dbo.AtencionStaging
    (LoteCarga, CodigoPaciente, CodigoEstablecimiento,
     TipoAtencion, DuracionMinutos, FechaAtencion)
VALUES
    ('LOTE-006','PAC-001','EST-001','CONSULTA',25,'2026-09-10'),
    ('LOTE-006','PAC-003','EST-001','CONSULTA',20,'2026-09-10'),
    ('LOTE-006','PAC-002','EST-002','CONTROL',12,'2026-09-10'),
    ('LOTE-006','PAC-001','EST-003','VACUNACION',15,'2026-09-10'),
    ('LOTE-006','PAC-002','EST-001','CONTROL',210,'2026-09-10');
GO

IF OBJECT_ID('dbo.ResultadoCargaFila', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ResultadoCargaFila(
        ResultadoId INT IDENTITY(1,1)
            CONSTRAINT PK_ResultadoCargaFila PRIMARY KEY,
        LoteCarga VARCHAR(20) NOT NULL,
        RegistroId INT NOT NULL,
        Resultado VARCHAR(10) NOT NULL,
        AtencionId INT NULL,
        NumeroError INT NULL,
        Mensaje VARCHAR(300) NULL,
        FechaProceso DATETIME2 NOT NULL
            CONSTRAINT DF_ResultadoCargaFila_Fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT CK_ResultadoCargaFila_Resultado
            CHECK (Resultado IN ('CARGADO','RECHAZADO'))
    );
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CargarLoteFilaPorFila
    @LoteCarga VARCHAR(20),
    @Cargadas INT OUTPUT,
    @Rechazadas INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;

    DECLARE
        @RegistroId INT,
        @PacienteId INT,
        @EstablecimientoId INT,
        @TipoAtencion VARCHAR(30),
        @DuracionMinutos INT,
        @A INT,
        @C VARCHAR(20),
        @M VARCHAR(300);

    BEGIN TRY
        SET @Cargadas = 0;
        SET @Rechazadas = 0;

        IF @LoteCarga IS NULL
            OR NOT EXISTS (
                SELECT 1
                FROM dbo.AtencionStaging
                WHERE LoteCarga = @LoteCarga
            )
        BEGIN
            THROW 53001, 'El lote es obligatorio y debe tener registros.', 1;
        END;

        BEGIN TRANSACTION;

        DECLARE cur_Filas CURSOR LOCAL FAST_FORWARD
        FOR
            SELECT
                S.RegistroId,
                P.PacienteId,
                E.EstablecimientoId,
                S.TipoAtencion,
                S.DuracionMinutos
            FROM dbo.AtencionStaging AS S
            LEFT JOIN dbo.Paciente AS P
                ON P.CodigoPaciente = S.CodigoPaciente
            LEFT JOIN dbo.EstablecimientoSalud AS E
                ON E.CodigoEstablecimiento = S.CodigoEstablecimiento
            WHERE S.LoteCarga = @LoteCarga
            ORDER BY S.RegistroId;

        OPEN cur_Filas;

        FETCH NEXT FROM cur_Filas
        INTO @RegistroId, @PacienteId, @EstablecimientoId,
             @TipoAtencion, @DuracionMinutos;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SAVE TRANSACTION AntesFila;

            BEGIN TRY
                EXEC dbo.usp_RegistrarAtencion
                    @PacienteId = @PacienteId,
                    @EstablecimientoId = @EstablecimientoId,
                    @TipoAtencion = @TipoAtencion,
                    @DuracionMinutos = @DuracionMinutos,
                    @AtencionId = @A OUTPUT,
                    @Clasificacion = @C OUTPUT,
                    @Mensaje = @M OUTPUT;

                INSERT INTO dbo.ResultadoCargaFila
                    (LoteCarga, RegistroId, Resultado, AtencionId, Mensaje)
                VALUES
                    (@LoteCarga, @RegistroId, 'CARGADO', @A, @M);

                SET @Cargadas += 1;
            END TRY
            BEGIN CATCH
                IF XACT_STATE() <> 1
                BEGIN
                    THROW;
                END;

                ROLLBACK TRANSACTION AntesFila;

                INSERT INTO dbo.ResultadoCargaFila
                    (LoteCarga, RegistroId, Resultado, NumeroError, Mensaje)
                VALUES
                    (@LoteCarga, @RegistroId, 'RECHAZADO',
                     ERROR_NUMBER(), LEFT(ERROR_MESSAGE(), 300));

                SET @Rechazadas += 1;
            END CATCH;

            FETCH NEXT FROM cur_Filas
            INTO @RegistroId, @PacienteId, @EstablecimientoId,
                 @TipoAtencion, @DuracionMinutos;
        END;

        CLOSE cur_Filas;
        DEALLOCATE cur_Filas;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur_Filas') >= 0
            CLOSE cur_Filas;

        IF CURSOR_STATUS('local', 'cur_Filas') >= -1
            DEALLOCATE cur_Filas;

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

DECLARE @Cargadas INT, @Rechazadas INT;
EXEC dbo.usp_CargarLoteFilaPorFila
    @LoteCarga = 'LOTE-006',
    @Cargadas = @Cargadas OUTPUT,
    @Rechazadas = @Rechazadas OUTPUT;

SELECT @Cargadas AS Cargadas, @Rechazadas AS Rechazadas,
       @@TRANCOUNT AS TransaccionesAbiertas;

SELECT RegistroId, Resultado, AtencionId, NumeroError, Mensaje
FROM dbo.ResultadoCargaFila
WHERE LoteCarga = 'LOTE-006'
ORDER BY RegistroId;

SELECT AlertaId, AtencionId, DuracionMinutos
FROM dbo.AlertaAtencion
WHERE DuracionMinutos = 210;
GO

SELECT RegistroId, CodigoPaciente, CodigoEstablecimiento, DuracionMinutos
FROM dbo.ufn_RegistrosAptosCarga('LOTE-006')
ORDER BY RegistroId;
GO
