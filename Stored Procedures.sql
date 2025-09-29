CREATE OR ALTER PROCEDURE usp_merge_dim_cliente
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE dim.dbr_cliente AS target
        USING (
            SELECT DISTINCT
                codigo_cliente,
                nombre_completo,
                CASE 
                    WHEN tipo_cliente = 'I' THEN 'I'
                    WHEN tipo_cliente = 'J' THEN 'J'
                    ELSE 'I' 
                END AS tipo_cliente,
                dpi,
                nit,
                fecha_alta
            FROM stage.clientes
            WHERE codigo_cliente IS NOT NULL
        ) AS source
        ON target.codigo_cliente = source.codigo_cliente

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (codigo_cliente, nombre, tipo_cliente, dpi, nit, fecha_creacion)
            VALUES (
                source.codigo_cliente,
                source.nombre_completo,
                source.tipo_cliente,
                source.dpi,
                source.nit,
                source.fecha_alta
            );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


CREATE OR ALTER PROCEDURE usp_merge_dim_agencia
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE dim.dbr_agencia AS target
        USING (
            SELECT DISTINCT
                agencia_codigo,
                nombre_agencia,
                direccion
            FROM stage.agencias
            WHERE agencia_codigo IS NOT NULL
        ) AS source
        ON target.agencia_codigo = source.agencia_codigo

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (agencia_codigo, nombre_agencia, direccion)
            VALUES (
                source.agencia_codigo,
                source.nombre_agencia,
                source.direccion
            );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


CREATE OR ALTER PROCEDURE usp_merge_dim_producto
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE dim.dbr_producto AS target
        USING (
            SELECT DISTINCT
                pf.numero_producto,
                c.cliente_id,
                pf.tipo_producto,
                pf.fecha_apertura
            FROM stage.productos_financieros pf
            INNER JOIN dim.dbr_cliente c
                ON pf.codigo_cliente = c.codigo_cliente
            WHERE pf.numero_producto IS NOT NULL
        ) AS source
        ON target.numero_producto = source.numero_producto

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (numero_producto, cliente_id, tipo_producto, fecha_apertura)
            VALUES (
                source.numero_producto,
                source.cliente_id,
                source.tipo_producto,
                source.fecha_apertura
            );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE usp_poblar_dim_fecha
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @fecha_actual DATE = @fecha_inicio;

        WHILE @fecha_actual <= @fecha_fin
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM dim.dbr_fecha WHERE fecha = @fecha_actual
            )
            BEGIN
                INSERT INTO dim.dbr_fecha (fecha, anio, mes, dia, trimestre, dia_semana)
                VALUES (
                    @fecha_actual,
                    YEAR(@fecha_actual),
                    MONTH(@fecha_actual),
                    DAY(@fecha_actual),
                    DATEPART(QUARTER, @fecha_actual),
                    DATEPART(WEEKDAY, @fecha_actual)
                );
            END

            SET @fecha_actual = DATEADD(DAY, 1, @fecha_actual);
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE usp_merge_dbr_transacciones
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE fact.dbr_transacciones AS target
        USING (
            SELECT DISTINCT
                st.id_transaccion,
                dp.producto_id,
                da.agencia_id,
                CAST(st.fecha_transaccion AS DATE) AS fecha,
                st.monto_transaccion,
                st.clasificacion_riesgo
            FROM stage.transacciones st
            INNER JOIN dim.dbr_producto dp
                ON st.numero_producto = dp.numero_producto
            LEFT JOIN dim.dbr_agencia da
                ON st.agencia_codigo = da.agencia_codigo
            WHERE st.id_transaccion IS NOT NULL
              AND EXISTS (
                  SELECT 1 FROM dim.dbr_fecha df
                  WHERE df.fecha = CAST(st.fecha_transaccion AS DATE)
              )
        ) AS source
        ON target.transaccion_id = source.id_transaccion

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                transaccion_id,
                producto_id,
                agencia_id,
                fecha,
                monto,
                clasificacion_riesgo
            )
            VALUES (
                source.id_transaccion,
                source.producto_id,
                source.agencia_id,
                source.fecha,
                source.monto_transaccion,
                source.clasificacion_riesgo
            );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE usp_merge_dbr_evaluaciones_riesgo
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE fact.dbr_evaluaciones_riesgo AS target
        USING (
            SELECT DISTINCT
                se.id_evaluacion,
                dc.cliente_id,
                se.fecha_evaluacion,
                se.clasificacion_riesgo
            FROM stage.evaluaciones_riesgo se
            INNER JOIN dim.dbr_cliente dc
                ON se.codigo_cliente = dc.codigo_cliente
            WHERE se.id_evaluacion IS NOT NULL
              AND EXISTS (
                  SELECT 1 FROM dim.dbr_fecha df
                  WHERE df.fecha = se.fecha_evaluacion
              )
        ) AS source
        ON target.evaluacion_id = source.id_evaluacion

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                evaluacion_id,
                cliente_id,
                fecha,
                clasificacion_riesgo
            )
            VALUES (
                source.id_evaluacion,
                source.cliente_id,
                source.fecha_evaluacion,
                source.clasificacion_riesgo
            );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO