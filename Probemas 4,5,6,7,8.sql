--Problema 4

SELECT DISTINCT
    c.cliente_id,
    c.codigo_cliente,
    c.nombre,
    p.numero_producto,
    t.transaccion_id,
    t.fecha,
    t.monto,
    t.clasificacion_riesgo
FROM fact.dbr_transacciones t
INNER JOIN dim.dbr_producto p ON t.producto_id = p.producto_id
INNER JOIN dim.dbr_cliente c ON p.cliente_id = c.cliente_id
WHERE t.clasificacion_riesgo IN ('D', 'E');


SELECT
    c.tipo_cliente,
    SUM(t.monto) AS saldo_total
FROM fact.dbr_transacciones t
INNER JOIN dim.dbr_producto p ON t.producto_id = p.producto_id
INNER JOIN dim.dbr_cliente c ON p.cliente_id = c.cliente_id
GROUP BY c.tipo_cliente;


SELECT
    er.evaluacion_id,
    df.fecha,
    er.clasificacion_riesgo
FROM fact.dbr_evaluaciones_riesgo er
INNER JOIN dim.dbr_cliente c ON er.cliente_id = c.cliente_id
INNER JOIN dim.dbr_fecha df ON er.fecha = df.fecha
WHERE c.codigo_cliente = '00f1a4b1-9cec-4879-b'
ORDER BY df.fecha;

--Problema 5

WITH SaldoMensual AS (
    SELECT
        c.cliente_id,
        c.codigo_cliente,
        c.nombre,
        FORMAT(t.fecha, 'yyyy-MM') AS periodo,
        SUM(t.monto) AS saldo_mensual
    FROM fact.dbr_transacciones t
    INNER JOIN dim.dbr_producto p ON t.producto_id = p.producto_id
    INNER JOIN dim.dbr_cliente c ON p.cliente_id = c.cliente_id
    GROUP BY c.cliente_id, c.codigo_cliente, c.nombre, FORMAT(t.fecha, 'yyyy-MM')
),
Crecimiento AS (
    SELECT
        cliente_id,
        codigo_cliente,
        nombre,
        periodo,
        saldo_mensual,
        LAG(saldo_mensual) OVER (PARTITION BY cliente_id ORDER BY periodo) AS saldo_anterior,
        CAST(
            (ISNULL(saldo_mensual, 0) - ISNULL(LAG(saldo_mensual) OVER (PARTITION BY cliente_id ORDER BY periodo), 0)) * 100.0 /
            NULLIF(ISNULL(LAG(saldo_mensual) OVER (PARTITION BY cliente_id ORDER BY periodo), 0), 0)
            AS DECIMAL(10,2)
        ) AS crecimiento_porcentual
    FROM SaldoMensual
),
SaldoTotal AS (
    SELECT
        cliente_id,
        codigo_cliente,
        nombre,
        SUM(saldo_mensual) AS saldo_total
    FROM SaldoMensual
    GROUP BY cliente_id, codigo_cliente, nombre
)
SELECT TOP 10
    st.codigo_cliente,
    st.nombre,
    FORMAT(st.saldo_total, 'C', 'es-GT') AS saldo_total_gtq,
    FORMAT(ISNULL(c.crecimiento_porcentual, 0), 'N2') + '%' AS crecimiento_mensual,
    er.clasificacion_riesgo
FROM SaldoTotal st
LEFT JOIN Crecimiento c ON st.cliente_id = c.cliente_id AND c.periodo = (
    SELECT MAX(periodo) FROM SaldoMensual WHERE cliente_id = st.cliente_id
)
LEFT JOIN fact.dbr_evaluaciones_riesgo er ON st.cliente_id = er.cliente_id
WHERE er.fecha = (
    SELECT MAX(fecha) FROM fact.dbr_evaluaciones_riesgo WHERE cliente_id = st.cliente_id
)
ORDER BY st.saldo_total DESC;

--Problema 6:

--problema 7

SELECT c.nombre, p.tipo_producto, t.fecha, t.monto
FROM transacciones t
INNER JOIN productos p ON p.producto_id = t.producto_id
INNER JOIN clientes c ON c.cliente_id = p.cliente_id
WHERE t.fecha >= '2024-01-01'
  AND t.monto > 50000
ORDER BY t.fecha DESC;

-- indices
CREATE INDEX idx_productos_producto_cliente
ON productos (producto_id)
INCLUDE (cliente_id, tipo_producto);


CREATE INDEX idx_clientes_id_nombre
ON clientes (cliente_id)
INCLUDE (nombre);

--problema 8 

-- Validación de formato + restricciones en una sola celda
SELECT * FROM stage.clientes
WHERE LEN(dpi) <> 13 OR dpi LIKE '%[^0-9]%'
   OR nit NOT LIKE '[0-9]%-[0-9]' OR nit LIKE '%[^0-9-]%'
   OR LEN(telefono) <> 8 OR telefono LIKE '%[^0-9]%';

--se agregan restricciones a las tablas para que puedan aceptar solamente estos formatos

ALTER TABLE stage.clientes
ADD CONSTRAINT chk_dpi_formato CHECK (
    LEN(dpi) = 13 AND dpi NOT LIKE '%[^0-9]%'
);

ALTER TABLE stage.clientes
ADD CONSTRAINT chk_nit_formato CHECK (
    nit LIKE '[0-9]%-[0-9]' AND nit NOT LIKE '%[^0-9-]%'
);

ALTER TABLE stage.clientes
ADD CONSTRAINT chk_telefono_formato CHECK (
    LEN(telefono) = 8 AND telefono NOT LIKE '%[^0-9]%'
);