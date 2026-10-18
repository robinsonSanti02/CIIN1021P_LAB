# Ejercicio 00 — Ética y responsabilidad profesional

**Curso:** Base de Datos Avanzadas y Big Data  
**Tema:** 01 — Fundamentos avanzados de bases de datos relacionales  
**Modalidad de desarrollo:** Individual; no se cuenta con grupo asignado (entrega configurada como grupal).  
**Autor:** SANTISTEBAN LLAGUENTO ROBINSON JAIR (único integrante).  
**Sección y fecha:** [COMPLETAR]

## Paso 2. Dos situaciones reales

| Campo | Situación A: Clínica Delgado | Situación B: base de datos atribuida al Minsa |
|---|---|---|
| ¿Qué pasó? | En febrero de 2025, se difundió por redes información médica confidencial de una paciente atendida en la clínica. La institución informó que identificó a personas implicadas e inició un proceso sancionador, además de colaborar con las autoridades. | En agosto de 2022, RPP informó que un usuario de un foro había puesto a la venta una base atribuida al Minsa con datos personales de aproximadamente 44 mil pacientes y había publicado una muestra como supuesta prueba. La alerta fue recogida por organismos de seguridad digital del Estado. |
| ¿Quiénes resultaron afectados? | La paciente cuya información clínica fue expuesta y, en términos de confianza y seguridad, los usuarios del establecimiento. | Las personas cuyos datos figuraban presuntamente en la base ofrecida; la cantidad exacta de personas efectivamente comprometidas requería validación oficial. |
| ¿Qué principio del CIP se vulneró? | Reserva y discreción de información confidencial, art. 45, literal c, según la numeración consignada en la guía del curso. La difusión de datos clínicos es incompatible con ese deber. | Reserva de información, art. 45, literal c; también resulta pertinente la diligencia técnica (art. 19) para prevenir accesos indebidos. Se analiza como riesgo y posible vulneración; no se atribuye responsabilidad personal no acreditada. |
| ¿Qué control técnico habría reducido el riesgo? | Acceso por roles y privilegios mínimos; registros de auditoría de consultas a historias clínicas; alertas de accesos inusuales y minimización de campos exportables. | Controles de acceso y revisión periódica de permisos; cifrado de copias y respaldos; auditoría de extracciones masivas y medidas contra exfiltración. |
| ¿Qué dato de la fuente no está confirmado? | La noticia no explica el mecanismo técnico exacto de la filtración ni determina públicamente cuántas copias externas circularon. La clínica afirmó que investigaba y revisaba sus procesos. | La noticia no confirma que los 44 mil registros ofrecidos sean auténticos, completos y exclusivos del sistema indicado ni cómo se obtuvo la base. El boletín recomendó verificar la información. |

**Fuentes periodísticas consultadas:**

- A. RPP Noticias, «Clínica Delgado anuncia que identificó e inició proceso sancionador por filtración de información médica», 17 de febrero de 2025. https://rpp.pe/peru/actualidad/shakira-en-lima-clinica-delgado-anuncia-que-identifico-e-inicio-proceso-sancionador-por-filtracion-de-informacion-medica-noticia-1616825
- B. RPP Noticias, «MINSA: Hacker vende datos privados de 44 mil pacientes», 18 de agosto de 2022. https://rpp.pe/tecnologia/mas-tecnologia/minsa-hacker-vende-datos-privados-de-44-mil-pacientes-noticia-1425567
- Colegio de Ingenieros del Perú, guía de consulta de su Código de Ética: https://www.cip.org.pe/reglamentos/

> Nota metodológica: las referencias a artículos 19 y 45(c) siguen la numeración indicada en la guía de la sesión. Antes de citar los artículos como versión legal vigente, contrastar el texto del CIP aplicable.

## Paso 3. Un dilema, una decisión

**Dilema elegido:** 2 — aparece una atención de 240 minutos y el director solicita eliminarla del lote para reducir el promedio.

- **Decisión:** Conservar la fila y marcarla como **OBSERVADA**, solicitando verificación antes de incorporarla a indicadores; no eliminarla ni darla por válida automáticamente.
- **Principio que la respalda:** Veracidad e independencia (art. 27, literal a) y competencia profesional (art. 33), conforme a la guía de trabajo.
- **Consecuencia y para quién:** Se protege la confiabilidad del reporte y el derecho a una interpretación adecuada de la atención, evitando ocultar una hospitalización real o consolidar un error de captura.
