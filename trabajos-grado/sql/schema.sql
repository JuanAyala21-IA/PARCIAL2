-- ============================================================
-- Sistema de Trabajos de Grado
-- Base de datos: trabajos_grado
-- Motor: MySQL 5.7+ / 8.x (compatible con Tomcat 9 + JSTL sql)
-- ============================================================

CREATE DATABASE IF NOT EXISTS trabajos_grado
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE trabajos_grado;

-- ------------------------------------------------------------
-- Tabla: roles
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS roles (
  id     INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: usuarios
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  codigo   VARCHAR(20)  NULL UNIQUE,
  nombre   VARCHAR(100) NOT NULL,
  correo   VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(128) NOT NULL COMMENT 'Hash SHA2 256 en hexadecimal (64 caracteres)',
  rol_id   INT NOT NULL,
  estado   VARCHAR(10) NOT NULL DEFAULT 'ACTIVO',
  CONSTRAINT fk_usuarios_rol FOREIGN KEY (rol_id) REFERENCES roles (id),
  CONSTRAINT ck_usuarios_estado CHECK (estado IN ('ACTIVO', 'INACTIVO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: ideas (banco de ideas)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ideas (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  titulo        VARCHAR(200) NOT NULL,
  descripcion   TEXT NOT NULL,
  area          VARCHAR(100) NULL,
  propuesta_por INT NULL COMMENT 'FK a usuarios.id (quien propone la idea)',
  estado        VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE',
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ideas_usuario FOREIGN KEY (propuesta_por) REFERENCES usuarios (id),
  CONSTRAINT ck_ideas_estado CHECK (estado IN ('DISPONIBLE', 'ASIGNADA', 'INACTIVA', 'POSTULADA'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: anteproyectos (luego escala a proyecto)
-- codigo formato GRA-00001
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS anteproyectos (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  codigo        VARCHAR(10)  NOT NULL UNIQUE COMMENT 'Formato GRA-00001',
  descripcion   TEXT NOT NULL,
  estudiante_id INT NULL,
  estudiante2_id INT NULL COMMENT 'Compañero de equipo (bloque 18)',
  director_id   INT NULL,
  evaluador_id  INT NULL,
  idea_id INT NULL COMMENT 'Idea del banco seleccionada por el estudiante (bloque 1)',
  idea_solicitada_id INT NULL COMMENT 'Idea elegida por el estudiante en Fase 1 (bloque 12)',
  obs_coordinacion TEXT NULL COMMENT 'Observaciones de Coordinación (bloques 13 y 16)',
  fecha_sustentacion DATE NULL COMMENT 'Fecha programada de sustentación (bloque 14)',
  nota_sustentacion DECIMAL(3,1) NULL COMMENT 'Nota de sustentación 0.0 a 5.0 (bloque 14)',
  fase          VARCHAR(30) NOT NULL DEFAULT 'ANTEPROYECTO',
  estado        VARCHAR(30) NOT NULL DEFAULT 'EN_REVISION',
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ante_estudiante FOREIGN KEY (estudiante_id) REFERENCES usuarios (id),
  CONSTRAINT fk_ante_estudiante2 FOREIGN KEY (estudiante2_id) REFERENCES usuarios (id),
  CONSTRAINT fk_ante_director   FOREIGN KEY (director_id)   REFERENCES usuarios (id),
  CONSTRAINT fk_ante_evaluador  FOREIGN KEY (evaluador_id)  REFERENCES usuarios (id),
  CONSTRAINT fk_ante_idea FOREIGN KEY (idea_id) REFERENCES ideas (id),
  CONSTRAINT fk_ante_idea_sol FOREIGN KEY (idea_solicitada_id) REFERENCES ideas (id),
  CONSTRAINT ck_ante_fase   CHECK (fase IN ('1', '2', '3', '4', '5', 'FINAL', 'IDEA', 'ANTEPROYECTO', 'PROYECTO', 'SUSTENTACION')),
  CONSTRAINT ck_ante_estado CHECK (estado IN ('ESTUDIANTE', 'DIRECTOR', 'EVALUADOR', 'COORDINACION', 'APROBADO', 'RECHAZADO', 'FINALIZADO', 'EN_REVISION', 'EN_DESARROLLO')),
  CONSTRAINT ck_ante_nota_sust CHECK (nota_sustentacion IS NULL OR (nota_sustentacion >= 0.0 AND nota_sustentacion <= 5.0)),
  CONSTRAINT ck_ante_est2_distinto CHECK (estudiante2_id IS NULL OR estudiante2_id <> estudiante_id),
  CONSTRAINT ck_director_distinto_evaluador CHECK (director_id IS NULL OR evaluador_id IS NULL OR director_id <> evaluador_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: calendario (actividades / cronograma institucional)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS calendario (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  actividad    VARCHAR(200) NOT NULL,
  fecha_inicio DATE NULL,
  fecha_fin    DATE NULL,
  descripcion  TEXT NULL,
  titulo VARCHAR(200) NULL COMMENT 'Titulo del evento (bloque 9)',
  tipo VARCHAR(20) NOT NULL DEFAULT 'OTRO' COMMENT 'ENTREGA, REUNION, SUSTENTACION u OTRO (bloque 9)',
  CONSTRAINT ck_calendario_tipo CHECK (tipo IN ('ENTREGA', 'REUNION', 'SUSTENTACION', 'OTRO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: formatos (base documental)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS formatos (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nombre      VARCHAR(100) NOT NULL,
  descripcion TEXT NULL,
  archivo_url VARCHAR(255) NULL COMMENT 'Ruta o URL del documento',
  estado      VARCHAR(10) NOT NULL DEFAULT 'ACTIVO',
  categoria VARCHAR(20) NOT NULL DEFAULT 'OTRO' COMMENT 'ANTEPROYECTO, INFORME, SUSTENTACION u OTRO (bloque 10)',
  enlace VARCHAR(500) NULL COMMENT 'URL al documento (bloque 10)',
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ck_formatos_estado CHECK (estado IN ('ACTIVO', 'INACTIVO')),
  CONSTRAINT ck_formatos_categoria CHECK (categoria IN ('ANTEPROYECTO', 'INFORME', 'SUSTENTACION', 'OTRO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: entregas por enlace (bloque 6)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS entregas (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  anteproyecto_id INT NOT NULL,
  fase           VARCHAR(2) NOT NULL COMMENT '1..5',
  enlace         VARCHAR(500) NOT NULL COMMENT 'URL a Drive, OneDrive, etc. Nunca archivos',
  comentario     TEXT NULL,
  enviado_por    INT NULL,
  fecha_envio    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_entregas_anteproyecto FOREIGN KEY (anteproyecto_id) REFERENCES anteproyectos (id),
  CONSTRAINT fk_entregas_usuario FOREIGN KEY (enviado_por) REFERENCES usuarios (id),
  CONSTRAINT ck_entregas_fase CHECK (fase IN ('1', '2', '3', '4', '5'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: revisiones del DIRECTOR (bloque 7, sin calificacion desde bloque 11)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS revisiones (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  anteproyecto_id INT NOT NULL,
  fase            VARCHAR(2) NOT NULL COMMENT '2 o 4 (fases que revisa el director)',
  director_id     INT NULL,
  observaciones   TEXT NULL,
  decision        VARCHAR(10) NOT NULL COMMENT 'APROBADO o DEVUELTO',
  fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_revisiones_anteproyecto FOREIGN KEY (anteproyecto_id) REFERENCES anteproyectos (id),
  CONSTRAINT fk_revisiones_director FOREIGN KEY (director_id) REFERENCES usuarios (id),
  CONSTRAINT ck_revisiones_decision CHECK (decision IN ('APROBADO', 'DEVUELTO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: evaluaciones del EVALUADOR (bloque 8, sin calificacion desde bloque 11)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS evaluaciones (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  anteproyecto_id INT NOT NULL,
  fase            VARCHAR(2) NOT NULL COMMENT '3 o 5 (fases que evalua el evaluador)',
  evaluador_id    INT NULL,
  observaciones   TEXT NULL,
  decision        VARCHAR(10) NOT NULL COMMENT 'APROBADO o DEVUELTO',
  fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_evaluaciones_anteproyecto FOREIGN KEY (anteproyecto_id) REFERENCES anteproyectos (id),
  CONSTRAINT fk_evaluaciones_evaluador FOREIGN KEY (evaluador_id) REFERENCES usuarios (id),
  CONSTRAINT ck_evaluaciones_decision CHECK (decision IN ('APROBADO', 'DEVUELTO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Tabla: avales (bloque 16: aval de Coordinación a la aprobación)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS avales (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  anteproyecto_id INT NOT NULL,
  fase            VARCHAR(2) NOT NULL COMMENT '3 o 5 (fase avalada)',
  coordinador_id  INT NOT NULL,
  decision        VARCHAR(12) NOT NULL COMMENT 'AVALADO o NO_AVALADO',
  observaciones   TEXT NULL,
  fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_avales_anteproyecto FOREIGN KEY (anteproyecto_id) REFERENCES anteproyectos (id),
  CONSTRAINT fk_avales_coordinador FOREIGN KEY (coordinador_id) REFERENCES usuarios (id),
  CONSTRAINT ck_avales_decision CHECK (decision IN ('AVALADO', 'NO_AVALADO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Datos iniciales: 4 roles (los docentes usan PROFESOR)
-- ------------------------------------------------------------
INSERT INTO roles (nombre) VALUES
  ('ADMINISTRADOR'),
  ('COORDINACION'),
  ('PROFESOR'),
  ('ESTUDIANTE')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);

-- ------------------------------------------------------------
-- Administrador inicial (password con SHA2 256)
-- Correo : admin@uts.edu.co
-- Clave  : admin123
-- Cambiar la clave despues del primer ingreso.
-- ------------------------------------------------------------
INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
SELECT 'ADM-001', 'Administrador del Sistema', 'admin@uts.edu.co',
       SHA2('admin123', 256),
       r.id, 'ACTIVO'
FROM roles r
WHERE r.nombre = 'ADMINISTRADOR'
ON DUPLICATE KEY UPDATE
  nombre = VALUES(nombre),
  password = VALUES(password),
  rol_id = VALUES(rol_id),
  estado = VALUES(estado);
