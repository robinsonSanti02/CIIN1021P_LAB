# Actividad de cierre — Tema 01

**1. ¿Cuál es la diferencia entre IF y CASE?**  
`IF...ELSE` dirige la ejecución de instrucciones hacia una u otra rama según la condición. `CASE` es una expresión que devuelve un valor, como la etiqueta CORTA o REGULAR según minutos.

**2. ¿Para qué sirve un parámetro OUTPUT?**  
Permite devolver un valor desde un procedimiento al código que lo invoca. En `usp_RegistrarAtencion`, devuelve el identificador generado, la clasificación y un mensaje.

**3. ¿Qué función cumple TRY...CATCH?**  
Intercepta errores durante la ejecución y permite tratarlos o devolver información controlada. En el procedimiento de registro se usa con `THROW` para rechazar datos incorrectos.

**4. ¿Para qué sirve una función definida por el usuario y qué aporta su reutilización?**  
Encapsula una regla que puede llamarse desde varias consultas u objetos. La clasificación por duración se mantiene en un solo lugar y reduce duplicación e inconsistencias.

**5. ¿Por qué validar antes de INSERT o UPDATE?**  
Porque las entradas pueden traer valores nulos, referencias inexistentes, tipos no admitidos o duraciones incoherentes. Comprobarlas evita incorporar información incorrecta y errores posteriores.

**6. ¿Por qué los mensajes de error deben evitar mostrar datos personales innecesarios?**  
Porque pueden almacenarse en registros, capturas o sistemas de monitoreo. Informar la regla incumplida sin nombres ni documentos de identidad reduce exposiciones evitables.

## Reflexiones adicionales

**Ejercicio 02: por qué centralizar la regla en una UDF.** Una función única facilita que consultas y procedimientos calculen la misma etiqueta con los mismos límites. Si la regla cambia, solo se modifica una definición y se evita corregir múltiples bloques `CASE` repetidos.

**Ejercicio 05: por qué revisar un OBSERVADO.** Un valor atípico de 240 minutos puede ser un error o una atención legítima. Eliminarlo destruiría evidencia; cargarlo directamente podría distorsionar indicadores. Debe quedar trazado para revisión.
