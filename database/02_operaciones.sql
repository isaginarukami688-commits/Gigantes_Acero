
CREATE TABLE categorias (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE,
    descripcion VARCHAR(250),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE equipos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_inventario VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(120) NOT NULL,
    descripcion TEXT,
    categoria_id BIGINT REFERENCES categorias(id),
    laboratorio_id BIGINT NOT NULL REFERENCES laboratorios(id),
    estado VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE'
        CHECK (estado IN (
            'DISPONIBLE', 'SOLICITADO', 'PRESTADO',
            'MANTENIMIENTO', 'BAJA'
        )),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE equipo_qr_index (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    equipo_id BIGINT NOT NULL UNIQUE REFERENCES equipos(id),
    codigo_qr VARCHAR(150) NOT NULL UNIQUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE solicitudes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id BIGINT NOT NULL REFERENCES usuarios(id),
    equipo_id BIGINT NOT NULL REFERENCES equipos(id),
    fecha_solicitud TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NOT NULL,
    motivo TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
        CHECK (estado IN (
            'PENDIENTE', 'APROBADA', 'RECHAZADA', 'CANCELADA'
        )),
    revisado_por BIGINT REFERENCES usuarios(id),
    revisado_en TIMESTAMPTZ,
    observaciones TEXT,
    CHECK (fecha_fin > fecha_inicio)
);

CREATE TABLE prestamos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    solicitud_id BIGINT UNIQUE REFERENCES solicitudes(id),
    usuario_id BIGINT NOT NULL REFERENCES usuarios(id),
    equipo_id BIGINT NOT NULL REFERENCES equipos(id),
    entregado_por BIGINT REFERENCES usuarios(id),
    recibido_por BIGINT REFERENCES usuarios(id),
    fecha_prestamo TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_devolucion_prevista TIMESTAMPTZ NOT NULL,
    fecha_devolucion_real TIMESTAMPTZ,
    estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO'
        CHECK (estado IN ('ACTIVO', 'DEVUELTO', 'VENCIDO')),
    observaciones TEXT,
    CHECK (
        fecha_devolucion_real IS NULL
        OR fecha_devolucion_real >= fecha_prestamo
    )
);

CREATE TABLE historial_estados (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    equipo_id BIGINT NOT NULL REFERENCES equipos(id),
    usuario_id BIGINT REFERENCES usuarios(id),
    estado_anterior VARCHAR(20),
    estado_nuevo VARCHAR(20) NOT NULL,
    fecha_cambio TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT
);

CREATE INDEX idx_equipos_laboratorio
    ON equipos(laboratorio_id);

CREATE INDEX idx_solicitudes_usuario_estado
    ON solicitudes(usuario_id, estado);

CREATE INDEX idx_prestamos_usuario_estado
    ON prestamos(usuario_id, estado);

CREATE INDEX idx_historial_equipo_fecha
    ON historial_estados(equipo_id, fecha_cambio);
