# chn_dw

Repositorio del modelo dimensional para el data warehouse bancario de CHN.  
Incluye scripts de creación de esquemas, tablas, procedimientos de carga (`MERGE`), validaciones de calidad, detección de anomalías y limpieza de datos.

## Estructura
- `dim`: dimensiones de cliente, producto, agencia y fecha  
- `fact`: hechos de transacciones y evaluaciones de riesgo  
- `stage`: staging para carga y validación

## Funcionalidades destacadas
- Validación de DPI, NIT y teléfono guatemalteco  
- Detección de lavado de dinero por anomalías en transacciones  
- Cálculo de crecimiento mensual y clasificación de riesgo SIB  
- Modelo visual compatible con dbdiagram.io

- Los incisos 4,5,6,7,8 se agregaron a un solo archivo SQL
- El diagrama ER se subio como una imagen que se creo en dbdiagram, el nombre de archivo es diagrama ER
- Existen los archivos DDL
- Y se crearon Stored Procedures para poblar el modelo dimensional
- En SSIS se ejecutan las cargas de datos y las ejecuciones de los SP

---
