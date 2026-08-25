-- 1. Activamos la extensión de PostGIS para manejo de coordenadas y mapas
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Tabla de Usuarios (Autenticación y Perfiles)
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(150) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('ADMIN', 'REPARTIDOR')),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla de Vehículos (Capacidad y Estado)
CREATE TABLE vehiculos (
    id SERIAL PRIMARY KEY,
    placa VARCHAR(10) UNIQUE NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('MOTO', 'VAN', 'CAMION')),
    capacidad_peso_kg DECIMAL(8, 2) NOT NULL CHECK (capacidad_peso_kg > 0),
    capacidad_volumen_m3 DECIMAL(8, 2) NOT NULL CHECK (capacidad_volumen_m3 > 0),
    estado VARCHAR(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'MANTENIMIENTO', 'INACTIVO'))
);

-- 4. Tabla de Repartidores (Asociado a Usuario, Vehículo y Ubicación GPS)
CREATE TABLE repartidores (
    id SERIAL PRIMARY KEY,
    usuario_id INT UNIQUE NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    vehiculo_id INT REFERENCES vehiculos(id) ON DELETE SET NULL,
    estado VARCHAR(20) DEFAULT 'DISPONIBLE' CHECK (estado IN ('DISPONIBLE', 'EN_RUTA', 'INACTIVO')),
    ubicacion_actual GEOMETRY(Point, 4326) -- Coordenadas WGS84 (Longitud, Latitud)
);

-- 5. Tabla de Zonas de Cobertura (Polígonos de PostGIS para la Ciudad)
CREATE TABLE zonas_cobertura (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    area GEOMETRY(Polygon, 4326) NOT NULL -- Área geográfica delimitada
);

-- 6. Tabla de Paquetes (Núcleo de Envíos)
CREATE TABLE paquetes (
    id SERIAL PRIMARY KEY,
    codigo_rastreo VARCHAR(30) UNIQUE NOT NULL,
    cliente_nombre VARCHAR(100) NOT NULL,
    cliente_telefono VARCHAR(20) NOT NULL,
    peso_kg DECIMAL(6, 2) NOT NULL CHECK (peso_kg > 0),
    volumen_m3 DECIMAL(6, 2) NOT NULL CHECK (volumen_m3 > 0),
    origen_direccion TEXT NOT NULL,
    origen_coordenadas GEOMETRY(Point, 4326) NOT NULL,
    destino_direccion TEXT NOT NULL,
    destino_coordenadas GEOMETRY(Point, 4326) NOT NULL,
    estado VARCHAR(20) DEFAULT 'REGISTRADO' CHECK (
        estado IN ('REGISTRADO', 'ASIGNADO', 'EN_RUTA', 'ENTREGADO', 'CANCELADO')
    ),
    repartidor_id INT REFERENCES repartidores(id) ON DELETE SET NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Tabla de Historial de Estados (Auditoría para Triggers)
CREATE TABLE historial_estados (
    id SERIAL PRIMARY KEY,
    paquete_id INT NOT NULL REFERENCES paquetes(id) ON DELETE CASCADE,
    estado_anterior VARCHAR(20),
    estado_nuevo VARCHAR(20) NOT NULL,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacion TEXT
);