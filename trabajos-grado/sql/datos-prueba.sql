-- ============================================================
-- datos-prueba.sql : datos de demostración del sistema
-- Ejecutar UNA sola vez, DESPUÉS de schema.sql y de TODOS los
-- bloques de cambios.sql (1 al 10), sobre la base trabajos_grado.
-- No borra ni modifica el administrador existente.
-- Todas las claves van con SHA2('...', 256) y estado ACTIVO.
-- Los INSERT usan subconsultas por correo/código/título
-- (nunca ids fijos) y guardas NOT EXISTS: es seguro reejecutarlo.
-- ============================================================

USE trabajos_grado;

-- ------------------------------------------------------------
-- 1. Usuarios de prueba (clave de todos: prueba123)
-- ------------------------------------------------------------
INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
SELECT 'COR-001', 'Coordinación Uno', 'coordinacion@uts.edu.co', SHA2('prueba123', 256), r.id, 'ACTIVO'
FROM roles r WHERE r.nombre = 'COORDINACION'
  AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.correo = 'coordinacion@uts.edu.co');

INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
SELECT 'DIR-001', 'Director Uno', 'director1@uts.edu.co', SHA2('prueba123', 256), r.id, 'ACTIVO'
FROM roles r WHERE r.nombre = 'PROFESOR'
  AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.correo = 'director1@uts.edu.co');

INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
SELECT 'DIR-002', 'Director Dos', 'director2@uts.edu.co', SHA2('prueba123', 256), r.id, 'ACTIVO'
FROM roles r WHERE r.nombre = 'PROFESOR'
  AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.correo = 'director2@uts.edu.co');

INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
SELECT 'EVA-001', 'Evaluador Uno', 'evaluador1@uts.edu.co', SHA2('prueba123', 256), r.id, 'ACTIVO'
FROM roles r WHERE r.nombre = 'PROFESOR'
  AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.correo = 'evaluador1@uts.edu.co');

INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
SELECT 'EVA-002', 'Evaluador Dos', 'evaluador2@uts.edu.co', SHA2('prueba123', 256), r.id, 'ACTIVO'
FROM roles r WHERE r.nombre = 'PROFESOR'
  AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.correo = 'evaluador2@uts.edu.co');

INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
SELECT 'EST-001', 'Estudiante Uno', 'estudiante1@uts.edu.co', SHA2('prueba123', 256), r.id, 'ACTIVO'
FROM roles r WHERE r.nombre = 'ESTUDIANTE'
  AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.correo = 'estudiante1@uts.edu.co');

INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
SELECT 'EST-002', 'Estudiante Dos', 'estudiante2@uts.edu.co', SHA2('prueba123', 256), r.id, 'ACTIVO'
FROM roles r WHERE r.nombre = 'ESTUDIANTE'
  AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.correo = 'estudiante2@uts.edu.co');

INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
SELECT 'EST-003', 'Estudiante Tres', 'estudiante3@uts.edu.co', SHA2('prueba123', 256), r.id, 'ACTIVO'
FROM roles r WHERE r.nombre = 'ESTUDIANTE'
  AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.correo = 'estudiante3@uts.edu.co');

INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
SELECT 'EST-004', 'Estudiante Cuatro', 'estudiante4@uts.edu.co', SHA2('prueba123', 256), r.id, 'ACTIVO'
FROM roles r WHERE r.nombre = 'ESTUDIANTE'
  AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.correo = 'estudiante4@uts.edu.co');

INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
SELECT 'EST-005', 'Estudiante Cinco', 'estudiante5@uts.edu.co', SHA2('prueba123', 256), r.id, 'ACTIVO'
FROM roles r WHERE r.nombre = 'ESTUDIANTE'
  AND NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.correo = 'estudiante5@uts.edu.co');

-- ------------------------------------------------------------
-- 2. Ideas (2 DISPONIBLE + 4 ASIGNADA, propuestas por coordinación)
-- ------------------------------------------------------------
INSERT INTO ideas (titulo, descripcion, area, propuesta_por, estado)
SELECT 'Riego automatizado con IoT', 'Sistema de riego controlado por sensores de humedad y app móvil.', 'IoT', u.id, 'DISPONIBLE'
FROM usuarios u WHERE u.correo = 'coordinacion@uts.edu.co'
  AND NOT EXISTS (SELECT 1 FROM ideas i WHERE i.titulo = 'Riego automatizado con IoT');

INSERT INTO ideas (titulo, descripcion, area, propuesta_por, estado)
SELECT 'App de tutorías UTS', 'Plataforma para agendar tutorías entre estudiantes y docentes.', 'Desarrollo web', u.id, 'DISPONIBLE'
FROM usuarios u WHERE u.correo = 'coordinacion@uts.edu.co'
  AND NOT EXISTS (SELECT 1 FROM ideas i WHERE i.titulo = 'App de tutorías UTS');

INSERT INTO ideas (titulo, descripcion, area, propuesta_por, estado)
SELECT 'Detección de plagas con visión artificial', 'Modelo de IA para detectar plagas en cultivos de la región.', 'Inteligencia artificial', u.id, 'ASIGNADA'
FROM usuarios u WHERE u.correo = 'coordinacion@uts.edu.co'
  AND NOT EXISTS (SELECT 1 FROM ideas i WHERE i.titulo = 'Detección de plagas con visión artificial');

INSERT INTO ideas (titulo, descripcion, area, propuesta_por, estado)
SELECT 'Historias clínicas digitales', 'Sistema de gestión de historias clínicas para IPS locales.', 'Salud digital', u.id, 'ASIGNADA'
FROM usuarios u WHERE u.correo = 'coordinacion@uts.edu.co'
  AND NOT EXISTS (SELECT 1 FROM ideas i WHERE i.titulo = 'Historias clínicas digitales');

INSERT INTO ideas (titulo, descripcion, area, propuesta_por, estado)
SELECT 'Monitoreo de calidad del aire', 'Red de sensores de bajo costo con tablero público.', 'IoT', u.id, 'ASIGNADA'
FROM usuarios u WHERE u.correo = 'coordinacion@uts.edu.co'
  AND NOT EXISTS (SELECT 1 FROM ideas i WHERE i.titulo = 'Monitoreo de calidad del aire');

INSERT INTO ideas (titulo, descripcion, area, propuesta_por, estado)
SELECT 'Reciclaje inteligente en campus', 'Puntos limpios con sensores de llenado y rutas óptimas.', 'Sostenibilidad', u.id, 'DISPONIBLE'
FROM usuarios u WHERE u.correo = 'coordinacion@uts.edu.co'
  AND NOT EXISTS (SELECT 1 FROM ideas i WHERE i.titulo = 'Reciclaje inteligente en campus');

-- ------------------------------------------------------------
-- 3. Anteproyectos GRA-90001 a GRA-90005 (uno por estudiante)
-- ------------------------------------------------------------
-- (1) Fase 1 / ESTUDIANTE, sin director ni idea (elige en Fase 1)
INSERT INTO anteproyectos (codigo, descripcion, estudiante_id, director_id, evaluador_id, idea_id, idea_solicitada_id, fase, estado)
SELECT 'GRA-90001', 'Riego automatizado con IoT', est.id, NULL, NULL, NULL, NULL, '1', 'ESTUDIANTE'
FROM usuarios est
WHERE est.correo = 'estudiante1@uts.edu.co'
  AND NOT EXISTS (SELECT 1 FROM anteproyectos a WHERE a.codigo = 'GRA-90001');

-- (2) Fase 1 / COORDINACION con idea solicitada (DISPONIBLE) y sin asignar
INSERT INTO anteproyectos (codigo, descripcion, estudiante_id, director_id, evaluador_id, idea_id, idea_solicitada_id, fase, estado)
SELECT 'GRA-90002', 'App de tutorías UTS', est.id, NULL, NULL, NULL, ide.id, '1', 'COORDINACION'
FROM usuarios est, ideas ide
WHERE est.correo = 'estudiante2@uts.edu.co' AND ide.titulo = 'App de tutorías UTS'
  AND NOT EXISTS (SELECT 1 FROM anteproyectos a WHERE a.codigo = 'GRA-90002');

-- (3) Fase 2 / DIRECTOR con director1 y evaluador1, listo para revisar
INSERT INTO anteproyectos (codigo, descripcion, estudiante_id, director_id, evaluador_id, idea_id, idea_solicitada_id, fase, estado)
SELECT 'GRA-90003', 'Detección de plagas con visión artificial', est.id, dir.id, eva.id, ide.id, ide.id, '2', 'DIRECTOR'
FROM usuarios est, usuarios dir, usuarios eva, ideas ide
WHERE est.correo = 'estudiante3@uts.edu.co' AND dir.correo = 'director1@uts.edu.co'
  AND eva.correo = 'evaluador1@uts.edu.co'
  AND ide.titulo = 'Detección de plagas con visión artificial'
  AND NOT EXISTS (SELECT 1 FROM anteproyectos a WHERE a.codigo = 'GRA-90003');

-- (4) Fase 3 / EVALUADOR con director1 + evaluador1 y revisión APROBADA
INSERT INTO anteproyectos (codigo, descripcion, estudiante_id, director_id, evaluador_id, idea_id, idea_solicitada_id, fase, estado)
SELECT 'GRA-90004', 'Historias clínicas digitales', est.id, dir.id, eva.id, ide.id, ide.id, '3', 'EVALUADOR'
FROM usuarios est, usuarios dir, usuarios eva, ideas ide
WHERE est.correo = 'estudiante4@uts.edu.co' AND dir.correo = 'director1@uts.edu.co'
  AND eva.correo = 'evaluador1@uts.edu.co' AND ide.titulo = 'Historias clínicas digitales'
  AND NOT EXISTS (SELECT 1 FROM anteproyectos a WHERE a.codigo = 'GRA-90004');

-- (5) Fase 3 / EVALUADOR con director2 y evaluador2, revisión APROBADA
INSERT INTO anteproyectos (codigo, descripcion, estudiante_id, director_id, evaluador_id, idea_id, idea_solicitada_id, fase, estado)
SELECT 'GRA-90005', 'Monitoreo de calidad del aire', est.id, dir.id, eva.id, ide.id, ide.id, '3', 'EVALUADOR'
FROM usuarios est, usuarios dir, usuarios eva, ideas ide
WHERE est.correo = 'estudiante5@uts.edu.co' AND dir.correo = 'director2@uts.edu.co'
  AND eva.correo = 'evaluador2@uts.edu.co'
  AND ide.titulo = 'Monitoreo de calidad del aire'
  AND NOT EXISTS (SELECT 1 FROM anteproyectos a WHERE a.codigo = 'GRA-90005');

-- ------------------------------------------------------------
-- 4. Entregas (enlaces de ejemplo https)
-- ------------------------------------------------------------
INSERT INTO entregas (anteproyecto_id, fase, enlace, comentario, enviado_por)
SELECT a.id, '1', 'https://drive.google.com/file/d/pago90001/view', 'Comprobante de pago.', a.estudiante_id
FROM anteproyectos a WHERE a.codigo = 'GRA-90001'
  AND NOT EXISTS (SELECT 1 FROM entregas e WHERE e.anteproyecto_id = a.id AND e.fase = '1');

INSERT INTO entregas (anteproyecto_id, fase, enlace, comentario, enviado_por)
SELECT a.id, '1', 'https://drive.google.com/file/d/pago90002/view', 'Comprobante de pago revisado.', a.estudiante_id
FROM anteproyectos a WHERE a.codigo = 'GRA-90002'
  AND NOT EXISTS (SELECT 1 FROM entregas e WHERE e.anteproyecto_id = a.id AND e.fase = '1');

INSERT INTO entregas (anteproyecto_id, fase, enlace, comentario, enviado_por)
SELECT a.id, '2', 'https://drive.google.com/file/d/propuesta90003/view', 'Propuesta versión 1.', a.estudiante_id
FROM anteproyectos a WHERE a.codigo = 'GRA-90003'
  AND NOT EXISTS (SELECT 1 FROM entregas e WHERE e.anteproyecto_id = a.id AND e.fase = '2');

-- ------------------------------------------------------------
-- 5. Revisiones APROBADAS del director (fases 2 de GRA-90004 y GRA-90005)
-- ------------------------------------------------------------
INSERT INTO revisiones (anteproyecto_id, fase, director_id, observaciones, decision)
SELECT a.id, '2', a.director_id, 'Propuesta aprobada con ajustes menores.', 'APROBADO'
FROM anteproyectos a WHERE a.codigo = 'GRA-90004'
  AND NOT EXISTS (SELECT 1 FROM revisiones r WHERE r.anteproyecto_id = a.id AND r.fase = '2');

INSERT INTO revisiones (anteproyecto_id, fase, director_id, observaciones, decision)
SELECT a.id, '2', a.director_id, 'Propuesta aprobada.', 'APROBADO'
FROM anteproyectos a WHERE a.codigo = 'GRA-90005'
  AND NOT EXISTS (SELECT 1 FROM revisiones r WHERE r.anteproyecto_id = a.id AND r.fase = '2');

-- ------------------------------------------------------------
-- 6. Eventos de calendario
-- ------------------------------------------------------------
INSERT INTO calendario (titulo, descripcion, tipo, fecha_inicio, fecha_fin)
SELECT 'Cierre de inscripciones', 'Último día para inscribir anteproyectos.', 'ENTREGA', CURDATE(), NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM calendario c WHERE c.titulo = 'Cierre de inscripciones');

INSERT INTO calendario (titulo, descripcion, tipo, fecha_inicio, fecha_fin)
SELECT 'Reunión de comité', 'Revisión de avances con el comité.', 'REUNION', DATE_ADD(CURDATE(), INTERVAL 15 DAY), NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM calendario c WHERE c.titulo = 'Reunión de comité');

INSERT INTO calendario (titulo, descripcion, tipo, fecha_inicio, fecha_fin)
SELECT 'Semana de sustentaciones', 'Sustentaciones públicas de grado.', 'SUSTENTACION', DATE_ADD(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 10 DAY)
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM calendario c WHERE c.titulo = 'Semana de sustentaciones');

INSERT INTO calendario (titulo, descripcion, tipo, fecha_inicio, fecha_fin)
SELECT 'Feria de proyectos', 'Exposición de proyectos del semestre.', 'OTRO', DATE_ADD(CURDATE(), INTERVAL 35 DAY), NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM calendario c WHERE c.titulo = 'Feria de proyectos');

-- ------------------------------------------------------------
-- 7. Formatos de grado (uno por categoría)
-- ------------------------------------------------------------
INSERT INTO formatos (nombre, descripcion, categoria, enlace)
SELECT 'Formato de anteproyecto', 'Plantilla oficial del documento de anteproyecto.', 'ANTEPROYECTO', 'https://ejemplo.uts.edu.co/formatos/anteproyecto'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM formatos f WHERE f.nombre = 'Formato de anteproyecto');

INSERT INTO formatos (nombre, descripcion, categoria, enlace)
SELECT 'Formato de informe final', 'Plantilla del informe final del proyecto.', 'INFORME', 'https://ejemplo.uts.edu.co/formatos/informe'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM formatos f WHERE f.nombre = 'Formato de informe final');

INSERT INTO formatos (nombre, descripcion, categoria, enlace)
SELECT 'Formato de sustentación', 'Guía y rúbrica de la sustentación.', 'SUSTENTACION', 'https://ejemplo.uts.edu.co/formatos/sustentacion'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM formatos f WHERE f.nombre = 'Formato de sustentación');

INSERT INTO formatos (nombre, descripcion, categoria, enlace)
SELECT 'Formato de solicitud general', 'Solicitudes varias a coordinación.', 'OTRO', 'https://ejemplo.uts.edu.co/formatos/solicitud'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM formatos f WHERE f.nombre = 'Formato de solicitud general');
