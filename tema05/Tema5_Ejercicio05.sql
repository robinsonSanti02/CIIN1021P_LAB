USE BDDataSaludTema05;
GO

IF OBJECT_ID(N'dw.DimGrupoEtario', N'U') IS NULL
    CREATE TABLE dw.DimGrupoEtario (
        GrupoEtarioKey INT PRIMARY KEY,
        EtapaVida VARCHAR(20) NOT NULL UNIQUE,
        EdadMinima TINYINT NULL,
        EdadMaxima TINYINT NULL
    );
GO

INSERT INTO dw.DimGrupoEtario (GrupoEtarioKey, EtapaVida, EdadMinima, EdadMaxima)
SELECT g.GrupoEtarioKey, g.EtapaVida, g.EdadMinima, g.EdadMaxima
FROM (VALUES
    (0,'NO REGISTRADO',NULL,NULL), (1,'NINO',0,11), (2,'ADOLESCENTE',12,17),
    (3,'JOVEN',18,29), (4,'ADULTO',30,59), (5,'ADULTO MAYOR',60,NULL)
) AS g (GrupoEtarioKey, EtapaVida, EdadMinima, EdadMaxima)
WHERE NOT EXISTS (SELECT 1 FROM dw.DimGrupoEtario AS d WHERE d.GrupoEtarioKey = g.GrupoEtarioKey);
GO

CREATE OR ALTER FUNCTION etl.ufn_EdadEnFecha (@FechaNacimiento DATE, @Fecha DATE)
RETURNS INT
AS
BEGIN
    IF @FechaNacimiento IS NULL OR @Fecha IS NULL OR @Fecha < @FechaNacimiento RETURN NULL;
    DECLARE @Edad INT = DATEDIFF(YEAR, @FechaNacimiento, @Fecha);
    IF DATEADD(YEAR, @Edad, @FechaNacimiento) > @Fecha SET @Edad = @Edad - 1;
    RETURN @Edad;
END;
GO

IF COL_LENGTH(N'dw.FactAtencion', N'GrupoEtarioKey') IS NULL
BEGIN
    ALTER TABLE dw.FactAtencion
    ADD GrupoEtarioKey INT NOT NULL CONSTRAINT DF_FactAtencion_GrupoEtarioKey DEFAULT (0),
        CONSTRAINT FK_FactAtencion_DimGrupoEtario FOREIGN KEY (GrupoEtarioKey)
            REFERENCES dw.DimGrupoEtario (GrupoEtarioKey);
END;
GO

WITH NacimientosPorAtencion AS (
    SELECT 'NUCLEO' AS Origen, CAST(a.AtencionId AS VARCHAR(10)) AS CodigoAtencion,
           p.FechaNacimiento
    FROM ope.Atencion AS a
    INNER JOIN ope.Paciente AS p ON p.PacienteId = a.PacienteId
    UNION ALL
    SELECT 'HIS', a.CodigoAtencion, p.FechaNacimiento
    FROM src.AtencionHIS AS a LEFT JOIN ope.Paciente AS p ON p.CodigoPaciente = a.CodigoPaciente
    UNION ALL
    SELECT 'CAMPANIA', a.CodigoAtencion, p.FechaNacimiento
    FROM src.AtencionCampania AS a LEFT JOIN ope.Paciente AS p ON p.CodigoPaciente = a.CodigoPaciente
)
UPDATE h SET GrupoEtarioKey = COALESCE(g.GrupoEtarioKey, 0)
FROM dw.FactAtencion AS h
INNER JOIN NacimientosPorAtencion AS n ON n.Origen = h.Origen AND n.CodigoAtencion = h.CodigoAtencion
INNER JOIN dw.DimFecha AS f ON f.FechaKey = h.FechaKey
CROSS APPLY (VALUES (etl.ufn_EdadEnFecha(n.FechaNacimiento, f.Fecha))) AS edad(Valor)
LEFT JOIN dw.DimGrupoEtario AS g
    ON edad.Valor >= g.EdadMinima AND (g.EdadMaxima IS NULL OR edad.Valor <= g.EdadMaxima)
WHERE h.GrupoEtarioKey <> COALESCE(g.GrupoEtarioKey, 0);

SELECT COUNT(*) AS Miembros FROM dw.DimGrupoEtario;
SELECT etl.ufn_EdadEnFecha('20081120','20261006') AS Edad1106,
       etl.ufn_EdadEnFecha('20081120','20261120') AS EdadCumple,
       etl.ufn_EdadEnFecha(NULL,'20261006') AS EdadSinDato;
SELECT COUNT(*) AS Hechos, SUM(DuracionMinutos) AS MinutosTotales,
       SUM(CASE WHEN GrupoEtarioKey = 0 THEN 1 ELSE 0 END) AS NoRegistrados
FROM dw.FactAtencion;
SELECT h.Origen, h.CodigoAtencion, g.EtapaVida
FROM dw.FactAtencion AS h
INNER JOIN dw.DimGrupoEtario AS g ON g.GrupoEtarioKey = h.GrupoEtarioKey
WHERE h.CodigoAtencion IN ('1106','CAM-002') ORDER BY h.CodigoAtencion;

SELECT f.Anio, f.Semestre, g.EtapaVida, COUNT(*) AS Atenciones,
       SUM(h.DuracionMinutos) AS MinutosTotales,
       CAST(AVG(CAST(h.DuracionMinutos AS DECIMAL(10,2))) AS DECIMAL(6,2)) AS PromedioMinutos
FROM dw.FactAtencion AS h
INNER JOIN dw.DimFecha AS f ON f.FechaKey = h.FechaKey
INNER JOIN dw.DimGrupoEtario AS g ON g.GrupoEtarioKey = h.GrupoEtarioKey
GROUP BY f.Anio, f.Semestre, g.EtapaVida ORDER BY f.Anio, f.Semestre, g.EtapaVida;
SELECT g.EtapaVida, COUNT(*) AS Atenciones, SUM(h.DuracionMinutos) AS MinutosTotales,
       CAST(AVG(CAST(h.DuracionMinutos AS DECIMAL(10,2))) AS DECIMAL(6,2)) AS PromedioMinutos
FROM dw.FactAtencion AS h INNER JOIN dw.DimGrupoEtario AS g ON g.GrupoEtarioKey = h.GrupoEtarioKey
GROUP BY g.EtapaVida ORDER BY g.EtapaVida;

SELECT Origen, MotivoRechazo, COUNT(*) AS FilasRechazadas
FROM stg.AtencionRechazada GROUP BY Origen, MotivoRechazo ORDER BY Origen, MotivoRechazo;
SELECT COUNT(*) AS ColumnasPersonalesEnDW
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dw'
  AND COLUMN_NAME IN ('PacienteId','CodigoPaciente','NombreSimulado','DocumentoSimulado','FechaNacimiento','Sexo');
GO
