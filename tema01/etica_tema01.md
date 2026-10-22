# Ejercicio 00 — Ética y responsabilidad profesional

**Curso:** Base de Datos Avanzadas y Big Data  
**Tema 01:** Fundamentos avanzados de bases de datos relacionales  
**Autor:** SANTISTEBAN LLAGUENTO ROBINSON JAIR  
**Fecha:** 22 de octubre de 2026

## Paso 2. Dos situaciones reales

| Campo | Situación A: Clínica Delgado | Situación B: base atribuida al Minsa |
|---|---|---|
| ¿Qué pasó? | Se inició un proceso sancionador por la filtración de datos médicos de una paciente. [2] | Se ofreció en internet una base atribuida al Minsa con datos de unos 44 mil pacientes. [3] |
| ¿Quiénes resultaron afectados? | La paciente cuya información fue difundida. El incidente compromete su intimidad y la confianza en la institución. | Las personas cuyos datos integrarían la base ofrecida. La exposición puede afectar su privacidad y facilitar usos indebidos. |
| ¿Qué principio del CIP se relaciona con el caso? | Reserva de la información, artículo 45, inciso c: el ingeniero debe proteger la información confidencial obtenida en su trabajo. Difundir datos clínicos contradice ese deber. [4] | Reserva de la información, artículo 45, inciso c: divulgar o comercializar información confidencial es incompatible con ese deber profesional. [4] |
| ¿Qué control técnico habría reducido el riesgo? | Acceso por roles y mínimo privilegio, con registro de consultas y exportaciones. Limita el acceso y permite examinar usos no justificados. | Restringir las exportaciones, revisar permisos y vigilar accesos inusuales; proteger respaldos y claves. Reduce la exposición y facilita detectar incidentes. |
| ¿Qué dato de la fuente no está confirmado? | La nota no detalla el mecanismo técnico de la filtración ni la sanción definitiva. No permite atribuir una vulnerabilidad informática específica. | La autenticidad integral y el origen técnico de la base requerían verificación; la noticia recoge esa necesidad de comprobación. |

El Código de Ética se aplica aquí como marco de análisis del deber profesional del ingeniero de datos. No se atribuyen sanciones del CIP a personas cuya profesión o responsabilidad no se acredita en las noticias. Se consulta la edición de 2018 publicada por el CIP. [4]

## Paso 3. Un dilema, una decisión

**Dilema elegido:** 2. Una atención registra 240 minutos y se propone eliminarla porque altera el promedio; aún no se sabe si es un error o un caso real.

**Decisión:** Conservar la fila de 240 minutos como `OBSERVADO` y remitirla a verificación, sin borrarla ni cambiar su valor.  
**Principio:** Veracidad e independencia basadas en hechos, artículo 27 a; consulta a especialistas cuando corresponda, artículo 33. [4]  
**Consecuencia:** Proteger al paciente y permitir decisiones de gestión sustentadas en datos verificados, sin ocultar una posible atención real.

## Fuentes

La numeración coincide con las referencias del informe.

[2] Agurto, E. (2025, 17 de febrero). *Clínica Delgado anuncia que identificó e inició proceso sancionador contra responsables de filtración de información médica de Shakira*. RPP Noticias.  
https://rpp.pe/peru/actualidad/shakira-en-lima-clinica-delgado-anuncia-que-identifico-e-inicio-proceso-sancionador-por-filtracion-de-informacion-medica-noticia-1616825

[3] Redacción RPP. (2022, 18 de agosto). *Hacker vende base de datos de 44 mil pacientes del Ministerio de Salud en internet*. RPP Noticias.  
https://rpp.pe/tecnologia/mas-tecnologia/minsa-hacker-vende-datos-privados-de-44-mil-pacientes-noticia-1425567

[4] Colegio de Ingenieros del Perú. (2018). *Código de Ética del Colegio de Ingenieros del Perú*. Artículos 27 a, 33 y 45 c.  
https://www.cip.org.pe/publicaciones/reglamentosCNCD2018/codigo_de_etica_del_cip.pdf

**Fecha de consulta:** 22 de octubre de 2026.
