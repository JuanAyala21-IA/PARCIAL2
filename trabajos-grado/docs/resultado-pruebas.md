# Resultado de pruebas — Trabajos de Grado

Respaldo previo: `sql/respaldo-pruebas.sql`. Base restaurada al final (usuarios 11, anteproyectos 5, entregas 3, estados originales). Sin cambios de código.

## 1. Lectura por rol (92/92 OK, cero 500)

| Rol | Lecturas OK | Denegados OK |
|---|---|---|
| ADMINISTRADOR | 25 (incl. `?q=&size=10&page=2`, crear/editar) | 3 (`revisar`, `evaluar`, `idea-seleccionar` → denegado) |
| COORDINACION | 18 | 3 (`usuarios`, `revisar`, `evaluar`) |
| DIRECTOR | 12 | 3 (`usuarios`, `evaluar`, `asignar-director`) |
| EVALUADOR | 10 | 3 (`usuarios`, `revisar`, `idea-form`) |
| ESTUDIANTE | 12 | 3 (`usuarios`, `revisar`, `asignar-director`) |

## 2. Flujo con POST (26 OK, 2 FALLO)

| # | Prueba | Rol | Resultado | Causa si falló |
|---|---|---|---|---|
| a | est5 selecciona idea 6 → GRA-00006 fase 1/ESTUDIANTE | ESTUDIANTE | OK | — |
| b | registra / edita / elimina / re-registra / envía enlace | ESTUDIANTE | OK | — |
| c | asigna director1 → fase 2/ESTUDIANTE | COORD | OK | — |
| d | devolver sin obs (rechazada), con obs (ok=7), reenvía, aprueba 4.5 (ok=6, fase 3) | DIR/EST | OK | — |
| e | asigna evaluador2 a GRA-90005 | COORD | OK | — |
| f | eva1 aprueba (ok=9, fase 4); eva2 devuelve (ok=10, fase 2) | EVALUADOR | OK | — |
| f | alerta "Tu evaluador devolvió" en seguimiento/entrega | ESTUDIANTE | FALLO | El `UNION` filtra `fase` = fase actual, pero la devolución queda registrada en fase 3 y el proyecto baja a 2. `seguimiento.jsp` L74-79, `entrega.jsp` L195-200 |
| g | admin crea/edita/elimina usuario; auto-borrado rechazado | ADMIN | OK | — |
| g | coord CRUD idea y formato | COORD | OK | — |
| g | coord crea evento | COORD | FALLO | `ERROR 1364: Field 'actividad' doesn't have a default value`. Los `INSERT` de `evento-form.jsp` (L77-96) omiten `actividad` (NOT NULL, schema) y el conector abre sesión con `STRICT_TRANS_TABLES`. Editar sí funciona (verificado ok=2) |
| g | coord edita evento | COORD | OK | — |

Nota: para 3a se marcó GRA-90005 como `FINALIZADO` (todos los seed tenían proyecto activo) y se revirtió a fase 3/`EVALUADOR` antes de 3e; el restore final lo deja todo como estaba.

## 3. Detalle de los 2 fallos (sin corregir)

1. **Alerta de devolución del evaluador** — `seguimiento.jsp` L74-79 y `entrega.jsp` L195-200: el `UNION ALL` exige `fase` = fase vigente; la devolución del evaluador se archiva en fase 3/5 y el proyecto regresa a 2/4 → la alerta nunca aparece.
2. **Crear evento** — `evento-form.jsp` L77-96: ningún `INSERT` incluye `actividad` (`VARCHAR(200) NOT NULL` sin default); con `STRICT_TRANS_TABLES` del conector falla con ERROR 1364 (probado en log general de MariaDB). El `UPDATE` de edición no toca esa columna y funciona.
