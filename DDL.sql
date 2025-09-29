-- Crear base y esquemas
CREATE DATABASE chn_dw;
GO
USE chn_dw;
GO

CREATE SCHEMA dim;
GO
CREATE SCHEMA fact;
GO
CREATE SCHEMA stage;
GO

-- Dim: Cliente
CREATE TABLE dim.dbr_cliente (
    cliente_id INT IDENTITY(1,1) PRIMARY KEY,
    codigo_cliente VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    tipo_cliente CHAR(1) NOT NULL CHECK (tipo_cliente IN ('I','J')),
    dpi CHAR(13) NULL,
    nit VARCHAR(15) NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- Dim: Producto
CREATE TABLE dim.dbr_producto (
    producto_id INT IDENTITY(1,1) PRIMARY KEY,
    numero_producto VARCHAR(50) NOT NULL UNIQUE,
    cliente_id INT NOT NULL,
    tipo_producto VARCHAR(50) NOT NULL CHECK (tipo_producto IN ('CUENTA','PRESTAMO','REMESA')),
    fecha_apertura DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_dbr_producto_cliente FOREIGN KEY (cliente_id)
        REFERENCES dim.dbr_cliente(cliente_id)
);
GO

-- Dim: Agencia
CREATE TABLE dim.dbr_agencia (
    agencia_id INT IDENTITY(1,1) PRIMARY KEY,
    agencia_codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre_agencia VARCHAR(200) NOT NULL,
    direccion VARCHAR(300) NULL
);
GO

-- Dim: Fecha
CREATE TABLE dim.dbr_fecha (
    fecha_id INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    anio INT NOT NULL,
    mes INT NOT NULL,
    dia INT NOT NULL,
    trimestre INT NOT NULL,
    dia_semana INT NOT NULL
);
GO

-- Hecho: Transacciones
CREATE TABLE fact.dbr_transacciones (
    transaccion_id BIGINT PRIMARY KEY,
    producto_id INT NOT NULL,
    agencia_id INT NULL,
    fecha DATE NOT NULL,
    monto DECIMAL(18,2) NOT NULL,
    clasificacion_riesgo CHAR(1) NULL CHECK (clasificacion_riesgo IN ('A','B','C','D','E')),
    CONSTRAINT FK_dbr_trans_producto FOREIGN KEY (producto_id)
        REFERENCES dim.dbr_producto(producto_id),
    CONSTRAINT FK_dbr_trans_agencia FOREIGN KEY (agencia_id)
        REFERENCES dim.dbr_agencia(agencia_id),
    CONSTRAINT FK_dbr_trans_fecha FOREIGN KEY (fecha)
        REFERENCES dim.dbr_fecha(fecha)
);
GO

-- Hecho: Evaluaciones
CREATE TABLE fact.dbr_evaluaciones_riesgo (
    evaluacion_id INT PRIMARY KEY,
    cliente_id INT NOT NULL,
    fecha DATE NOT NULL,
    clasificacion_riesgo CHAR(1) NOT NULL CHECK (clasificacion_riesgo IN ('A','B','C','D','E')),
    CONSTRAINT FK_dbr_eval_cliente FOREIGN KEY (cliente_id)
        REFERENCES dim.dbr_cliente(cliente_id),
    CONSTRAINT FK_dbr_eval_fecha FOREIGN KEY (fecha)
        REFERENCES dim.dbr_fecha(fecha)
);
GO

-- Stage: Clientes
CREATE TABLE stage.clientes (
    codigo_cliente VARCHAR(50),
    nombre_completo VARCHAR(200),
    tipo_cliente VARCHAR(5),
    dpi VARCHAR(13),
    nit VARCHAR(15),
    fecha_alta DATETIME,
    estado_cliente VARCHAR(50)
);
GO

-- Stage: Productos
CREATE TABLE stage.productos_financieros (
    numero_producto VARCHAR(50),
    codigo_cliente VARCHAR(50),
    tipo_producto VARCHAR(50),
    saldo_actual DECIMAL(18,2),
    fecha_apertura DATETIME,
    estado_producto VARCHAR(50),
    tasa_interes DECIMAL(5,2),
    plazo_meses INT
);
GO

-- Stage: Transacciones
CREATE TABLE stage.transacciones (
    id_transaccion BIGINT,
    numero_producto VARCHAR(50),
    fecha_transaccion DATETIME,
    monto_transaccion DECIMAL(18,2),
    tipo_transaccion VARCHAR(50),
    canal_transaccion VARCHAR(50),
    agencia_codigo VARCHAR(50),
    clasificacion_riesgo CHAR(1)
);
GO

-- Stage: Agencias
CREATE TABLE stage.agencias (
    agencia_codigo VARCHAR(50),
    nombre_agencia VARCHAR(200),
    direccion VARCHAR(300)
);
GO

-- Stage: Evaluaciones
CREATE TABLE stage.evaluaciones_riesgo (
    id_evaluacion INT,
    codigo_cliente VARCHAR(50),
    fecha_evaluacion DATE,
    clasificacion_riesgo CHAR(1),
    motivo VARCHAR(500),
    evaluador VARCHAR(100)
);
GO