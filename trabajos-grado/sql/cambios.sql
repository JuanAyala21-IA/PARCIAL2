-- ============================================================
-- cambios.sql : seleccion de idea por el ESTUDIANTE
-- Ejecutar UNA sola vez, despues de schema.sql.
-- Motor: MySQL 8.0.16+ o MariaDB 10.2+ (por el DROP CHECK).
-- En MySQL 5.7 los CHECK se ignoran: si el DROP CHECK falla ahi,
-- ejecute solo el bloque 1 (la columna) e ignore ese error.
-- ============================================================

USE trabajos_grado;

-- ------------------------------------------------------------
-- Bloque 1: idea_id nullable con FK a ideas
-- ------------------------------------------------------------
ALTER TABLE anteproyectos
  ADD COLUMN idea_id INT NULL COMMENT 'Idea del banco seleccionada por el estudiante',
  ADD CONSTRAINT fk_ante_idea FOREIGN KEY (idea_id) REFERENCES ideas (id);

-- ------------------------------------------------------------
-- Bloque 2: permitir fase '1' (idea recien seleccionada, fase inicial)
-- El CHECK original solo aceptaba IDEA/ANTEPROYECTO/PROYECTO/SUSTENTACION.
-- ------------------------------------------------------------
ALTER TABLE anteproyectos DROP CONSTRAINT ck_ante_fase;
ALTER TABLE anteproyectos
  ADD CONSTRAINT ck_ante_fase
  CHECK (fase IN ('1', 'IDEA', 'ANTEPROYECTO', 'PROYECTO', 'SUSTENTACION'));

-- ------------------------------------------------------------
-- Bloque 3: permitir estado 'ESTUDIANTE' (proyecto en curso sin director)
-- El CHECK original no incluia este estado inicial.
-- ------------------------------------------------------------
ALTER TABLE anteproyectos DROP CONSTRAINT ck_ante_estado;
ALTER TABLE anteproyectos
  ADD CONSTRAINT ck_ante_estado
  CHECK (estado IN ('ESTUDIANTE', 'EN_REVISION', 'APROBADO', 'RECHAZADO', 'EN_DESARROLLO', 'FINALIZADO'));

-- ============================================================
-- Bloques 4-5 : pantalla "Mis proyectos" (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-3, ejecute SOLO desde aqui.
-- ============================================================

-- ------------------------------------------------------------
-- Bloque 4: ampliar fase a '1','2','3','4','5','FINAL'
-- Se conservan los valores anteriores para no romper filas existentes.
-- ------------------------------------------------------------
ALTER TABLE anteproyectos DROP CONSTRAINT ck_ante_fase;
ALTER TABLE anteproyectos
  ADD CONSTRAINT ck_ante_fase
  CHECK (fase IN ('1', '2', '3', '4', '5', 'FINAL',
                  'IDEA', 'ANTEPROYECTO', 'PROYECTO', 'SUSTENTACION'));

-- ------------------------------------------------------------
-- Bloque 5: ampliar estado con 'DIRECTOR','EVALUADOR','COORDINACION'
-- (turno de cada fase) conservando los valores anteriores.
-- ------------------------------------------------------------
ALTER TABLE anteproyectos DROP CONSTRAINT ck_ante_estado;
ALTER TABLE anteproyectos
  ADD CONSTRAINT ck_ante_estado
  CHECK (estado IN ('ESTUDIANTE', 'DIRECTOR', 'EVALUADOR', 'COORDINACION',
                    'APROBADO', 'RECHAZADO', 'FINALIZADO',
                    'EN_REVISION', 'EN_DESARROLLO'));

-- ============================================================
-- Bloque 6 : tabla de entregas por enlace (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-5, ejecute SOLO desde aqui.
-- Un anteproyecto puede tener varias entregas por fase (historial).
-- ============================================================
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
) ENGINE=InnoDB;

-- ============================================================
-- Bloque 7 : tabla de revisiones del DIRECTOR (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-6, ejecute SOLO desde aqui.
-- Nota: estado 'EVALUADOR' ya existe desde el bloque 5, sin cambios.
-- ============================================================
CREATE TABLE IF NOT EXISTS revisiones (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  anteproyecto_id INT NOT NULL,
  fase            VARCHAR(2) NOT NULL COMMENT '2 o 4 (fases que revisa el director)',
  director_id     INT NULL,
  calificacion    DECIMAL(3,1) NOT NULL,
  observaciones   TEXT NULL,
  decision        VARCHAR(10) NOT NULL COMMENT 'APROBADO o DEVUELTO',
  fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_revisiones_anteproyecto FOREIGN KEY (anteproyecto_id) REFERENCES anteproyectos (id),
  CONSTRAINT fk_revisiones_director FOREIGN KEY (director_id) REFERENCES usuarios (id),
  CONSTRAINT ck_revisiones_nota CHECK (calificacion BETWEEN 0.0 AND 5.0),
  CONSTRAINT ck_revisiones_decision CHECK (decision IN ('APROBADO', 'DEVUELTO'))
) ENGINE=InnoDB;

-- ============================================================
-- Bloque 8 : tabla de evaluaciones del EVALUADOR (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-7, ejecute SOLO desde aqui.
-- Nota: estados 'COORDINACION' y 'ESTUDIANTE' ya existen desde el
-- bloque 5, y fase 'FINAL' desde el bloque 4. Sin cambios.
-- ============================================================
CREATE TABLE IF NOT EXISTS evaluaciones (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  anteproyecto_id INT NOT NULL,
  fase            VARCHAR(2) NOT NULL COMMENT '3 o 5 (fases que evalua el evaluador)',
  evaluador_id    INT NULL,
  calificacion    DECIMAL(3,1) NOT NULL,
  observaciones   TEXT NULL,
  decision        VARCHAR(10) NOT NULL COMMENT 'APROBADO o DEVUELTO',
  fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_evaluaciones_anteproyecto FOREIGN KEY (anteproyecto_id) REFERENCES anteproyectos (id),
  CONSTRAINT fk_evaluaciones_evaluador FOREIGN KEY (evaluador_id) REFERENCES usuarios (id),
  CONSTRAINT ck_evaluaciones_nota CHECK (calificacion BETWEEN 0.0 AND 5.0),
  CONSTRAINT ck_evaluaciones_decision CHECK (decision IN ('APROBADO', 'DEVUELTO'))
) ENGINE=InnoDB;

-- ============================================================
-- Bloque 9 : columnas del calendario (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-8, ejecute SOLO desde aqui.
-- La tabla tenia actividad/fecha_inicio/fecha_fin/descripcion;
-- se agregan titulo (se copia desde actividad) y tipo.
-- ============================================================
ALTER TABLE calendario
  ADD COLUMN titulo VARCHAR(200) NULL COMMENT 'Titulo del evento',
  ADD COLUMN tipo VARCHAR(20) NOT NULL DEFAULT 'OTRO' COMMENT 'ENTREGA, REUNION, SUSTENTACION u OTRO',
  ADD CONSTRAINT ck_calendario_tipo CHECK (tipo IN ('ENTREGA', 'REUNION', 'SUSTENTACION', 'OTRO'));

UPDATE calendario SET titulo = actividad WHERE titulo IS NULL;

-- ============================================================
-- Bloque 10 : columnas de formatos (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-9, ejecute SOLO desde aqui.
-- La tabla tenia nombre/descripcion/archivo_url/estado;
-- se agregan categoria, enlace (se copia desde archivo_url)
-- y fecha_registro. archivo_url se conserva intacta.
-- ============================================================
ALTER TABLE formatos
  ADD COLUMN categoria VARCHAR(20) NOT NULL DEFAULT 'OTRO' COMMENT 'ANTEPROYECTO, INFORME, SUSTENTACION u OTRO',
  ADD COLUMN enlace VARCHAR(500) NULL COMMENT 'URL al documento (Drive, OneDrive, etc.)',
  ADD COLUMN fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD CONSTRAINT ck_formatos_categoria CHECK (categoria IN ('ANTEPROYECTO', 'INFORME', 'SUSTENTACION', 'OTRO'));

UPDATE formatos SET enlace = archivo_url WHERE enlace IS NULL AND archivo_url IS NOT NULL;

-- ============================================================
-- Bloque 12 : idea solicitada por el estudiante (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-11, ejecute SOLO desde aqui.
-- El estudiante elige la idea desde su proyecto en Fase 1;
-- ya no se selecciona directamente del banco.
-- ============================================================
ALTER TABLE anteproyectos
  ADD COLUMN IF NOT EXISTS idea_solicitada_id INT NULL COMMENT 'Idea elegida por el estudiante en Fase 1',
  ADD CONSTRAINT fk_ante_idea_sol FOREIGN KEY (idea_solicitada_id) REFERENCES ideas (id);

UPDATE anteproyectos SET idea_solicitada_id = idea_id WHERE idea_id IS NOT NULL;

-- ============================================================
-- Bloque 11 : eliminar calificaciones (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-10, ejecute SOLO desde aqui.
-- El sistema ya no lleva notas: se quitan las columnas
-- calificacion de anteproyectos, revisiones y evaluaciones
-- (primero sus CHECK, sintaxis compatible con MariaDB 10.4).
-- ============================================================
ALTER TABLE revisiones DROP CONSTRAINT ck_revisiones_nota;
ALTER TABLE revisiones DROP COLUMN calificacion;
ALTER TABLE evaluaciones DROP CONSTRAINT ck_evaluaciones_nota;
ALTER TABLE evaluaciones DROP COLUMN calificacion;
ALTER TABLE anteproyectos DROP COLUMN calificacion;

-- ============================================================
-- Bloque 13 : observaciones de coordinación (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-12, ejecute SOLO desde aqui.
-- La solicitud de Fase 1 puede devolverse con observaciones.
-- ============================================================
ALTER TABLE anteproyectos
  ADD COLUMN IF NOT EXISTS obs_coordinacion TEXT NULL COMMENT 'Observaciones al devolver la solicitud de Fase 1';

-- ============================================================
-- Bloque 14 : sustentación (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-13, ejecute SOLO desde aqui.
-- Fecha y nota de sustentación; el estado 'FINALIZADO' ya existe.
-- ============================================================
ALTER TABLE anteproyectos
  ADD COLUMN IF NOT EXISTS fecha_sustentacion DATE NULL COMMENT 'Fecha programada de sustentación',
  ADD COLUMN IF NOT EXISTS nota_sustentacion DECIMAL(3,1) NULL COMMENT 'Nota de sustentación 0.0 a 5.0',
  ADD CONSTRAINT ck_ante_nota_sust CHECK (nota_sustentacion IS NULL OR (nota_sustentacion >= 0.0 AND nota_sustentacion <= 5.0));

-- ============================================================
-- Bloque 15 : rol único PROFESOR (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-14, ejecute SOLO desde aqui.
-- Los docentes DIRECTOR/EVALUADOR pasan a PROFESOR; Coordinación
-- decide por proyecto quién dirige y quién evalúa (distintos).
-- ============================================================
INSERT INTO roles (nombre)
SELECT 'PROFESOR' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE nombre = 'PROFESOR');

UPDATE usuarios SET rol_id = (SELECT id FROM roles WHERE nombre = 'PROFESOR')
WHERE rol_id IN (SELECT id FROM roles WHERE nombre IN ('DIRECTOR', 'EVALUADOR'));

ALTER TABLE anteproyectos
  ADD CONSTRAINT ck_director_distinto_evaluador
  CHECK (director_id IS NULL OR evaluador_id IS NULL OR director_id <> evaluador_id);

DELETE FROM roles WHERE nombre IN ('DIRECTOR', 'EVALUADOR');

-- ============================================================
-- Bloque 16 : avales de coordinación (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-15, ejecute SOLO desde aqui.
-- Coordinación avala (o no) la aprobación del evaluador en fase 3/5.
-- ============================================================
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

-- ============================================================
-- Bloque 17 : ideas postuladas por estudiantes (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-16, ejecute SOLO desde aqui.
-- La Fase 1 permite al estudiante postular su propia idea: se guarda en
-- ideas con estado 'POSTULADA' y propuesta_por = estudiante; Coordinacion
-- la aprueba (ASIGNADA) o la devuelve, y el CHECK acepta el nuevo estado.
-- ============================================================
ALTER TABLE ideas DROP CONSTRAINT ck_ideas_estado;

ALTER TABLE ideas
  ADD CONSTRAINT ck_ideas_estado
  CHECK (estado IN ('DISPONIBLE', 'ASIGNADA', 'INACTIVA', 'POSTULADA'));

-- ============================================================
-- Bloque 18 : equipo de 2 estudiantes (ejecutar si aun no se hizo)
-- Si ya ejecuto los bloques 1-17, ejecute SOLO desde aqui.
-- Un proyecto puede hacerse en equipo: estudiante2_id es el companero
-- de equipo (nunca igual al estudiante principal).
-- ============================================================
ALTER TABLE anteproyectos
  ADD COLUMN IF NOT EXISTS estudiante2_id INT NULL COMMENT 'Companero de equipo (segundo estudiante)',
  ADD CONSTRAINT fk_ante_estudiante2 FOREIGN KEY (estudiante2_id) REFERENCES usuarios (id),
  ADD CONSTRAINT ck_ante_est2_distinto CHECK (estudiante2_id IS NULL OR estudiante2_id <> estudiante_id);
