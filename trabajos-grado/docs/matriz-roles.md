# Matriz de roles — Sistema de Trabajos de Grado

Auditoría (solo lectura, sin servidor). Fuente: `includes/sidebar.jsp`,
`includes/guard.jsp` (`rolesPermitidos`) y las páginas JSP.

## 1. Ítems del sidebar por rol

| Ítem (destino) | ADMINISTRADOR | COORDINACION | PROFESOR | ESTUDIANTE |
|---|---|---|---|---|
| Inicio (`index.jsp`) | Sí | Sí | Sí | Sí |
| Usuarios (`usuarios.jsp`) | Sí | — | — | — |
| Mi perfil (`perfil.jsp`) | Sí | Sí | Sí | Sí |
| Banco de ideas (`ideas.jsp`) | Sí | Sí | Sí | Sí |
| Mis proyectos (`mis-proyectos.jsp`) | Sí | Sí | Sí | Sí |
| Informes (`informes.jsp`) | Sí | Sí | — | — |
| Mis prácticas (`practicas.jsp`) | Sí | Sí | — | Sí |
| Base documental (`formatos.jsp`) | Sí | Sí | Sí | Sí |
| Calendario (`calendario.jsp`) | Sí | Sí | Sí | Sí |

*Nota: ya no existen los roles DIRECTOR ni EVALUADOR. Los docentes usan el rol PROFESOR y son directores o evaluadores según el proyecto (nunca ambos en el mismo proyecto).*


## 2. Páginas que puede abrir cada rol (guard + alcance)

| Página | ADMIN | COORD | PROFESOR | ESTUDIANTE |
|---|---|---|---|---|
| `usuarios.jsp`, `usuario-form.jsp`, `usuario-ver.jsp`, `usuario-eliminar.jsp`, `usuario-eliminar-confirmar.jsp`, `usuario-eliminar-definitivo.jsp`, `usuario-estado.jsp` | Sí | — | — | — |
| `ideas.jsp`, `idea-ver.jsp` | Sí | Sí | Sí | Sí |
| `idea-form.jsp`, `idea-eliminar.jsp` | — | Sí | — | — |
| `mis-proyectos.jsp`, `proyecto-ver.jsp`, `seguimiento.jsp`, `entrega.jsp`, `sustentacion.jsp` | Sí (todo) | Sí (todo) | Sí (director o evaluador) | Sí (propio o del equipo) |
| `fase-enviar.jsp`, `iniciar-proyecto.jsp` | — | — | — | Sí (miembro del equipo, fase vigente) |
| `entrega-eliminar.jsp` | — | — | Sí (propio, fase vigente) | Sí (enlace propio, fase vigente) |
| `atender-solicitud.jsp`, `informes.jsp`, `proyecto-finalizar.jsp` | Sí | Sí | — | — |
| `revisar.jsp` | — | — | Sí (director, turno) | — |
| `evaluar.jsp` | — | — | Sí (evaluador, turno) | — |
| `avalar.jsp` | Sí | Sí | — | — |
| `calendario.jsp`, `formatos.jsp` | Sí (CRUD con form/eliminar) | Sí (CRUD) | Sí (ver/abrir) | Sí (ver/abrir) |
| `evento-form.jsp`, `evento-eliminar.jsp`, `formato-form.jsp`, `formato-eliminar.jsp` | Sí | Sí | — | — |
| `perfil.jsp`, `practicas.jsp` | Sí | Sí | Sí | Sí |

## 3. Acciones vs. requerimientos

| Rol | Requerimiento | Estado | Dónde |
|---|---|---|---|
| ADMINISTRADOR | Crear usuarios | OK | `usuario-form.jsp` (sin `?id`) |
| ADMINISTRADOR | Ver usuarios | OK | `usuarios.jsp`, `usuario-ver.jsp` |
| ADMINISTRADOR | Editar usuarios | OK | `usuario-form.jsp` (`?id`) |
| ADMINISTRADOR | Eliminar usuarios | OK | `usuario-eliminar.jsp` (POST: anti-autoborrado `error=propio`, anti-último-admin `error=ultimo-admin`; sin historial → DELETE directo `ok=3`) → `usuario-eliminar-confirmar.jsp` (resumen por subconsultas escalares, "Marcar como INACTIVO/ACTIVO" vía `usuario-estado.jsp`, "Eliminar definitivamente" escribiendo `ELIMINAR` + aviso rojo; PROFESOR/COORDINACION/ADMINISTRADOR con historial eligen heredero obligatorio entre los válidos —un PROFESOR no puede ser el otro responsable en ningún proyecto—; sin herederos válidos o con una FK no cubierta se bloquea con el nombre de la tabla) → `usuario-eliminar-definitivo.jsp` (POST, una sola `sql:transaction` con revalidación completa; ESTUDIANTE: con compañero, el compañero pasa a principal y recibe entregas e ideas del usuario, sin compañero se eliminan el proyecto y sus avales/evaluaciones/revisiones/entregas y la idea del banco vuelve a DISPONIBLE; como compañero solo sale del equipo y sus entregas pasan al principal; PROFESOR/COORDINACION/ADMINISTRADOR: TODAS las relaciones se transfieren al heredero; cualquier fallo revierte todo; éxito → flash en sesión con los conteos) |
| COORDINACION | CRUD de ideas | OK | `ideas.jsp`, `idea-form.jsp`, `idea-ver.jsp`, `idea-eliminar.jsp` (las ideas POSTULADA de estudiantes quedan fuera del banco: solo las ven el autor, su compañero de equipo, Coordinación y el administrador, y no se editan/eliminan desde el banco) |
| COORDINACION | Atender solicitud (idea, director, evaluador) | OK | `atender-solicitud.jsp` (fase 1 → 2) |
| COORDINACION | Avalar aprobación del evaluador | OK | `avalar.jsp` (fase 3→4 `ESTUDIANTE`, fase 5→`FINAL` `COORDINACION`; NO AVALADO → `EVALUADOR` misma fase) + botón fa-file-signature en `mis-proyectos.jsp`/`proyecto-ver.jsp` + filtro `?avales=1` |
| COORDINACION | Informes alumnos/director/evaluador | OK | `informes.jsp` (`?tipo=`) |
| COORDINACION | Calendario | OK | `calendario.jsp`, `evento-form.jsp`, `evento-eliminar.jsp` |
| COORDINACION | Formatos | OK | `formatos.jsp`, `formato-form.jsp`, `formato-eliminar.jsp` |
| COORDINACION | Registrar fecha, nota de sustentación y finalizar | OK | `sustentacion.jsp`, `proyecto-finalizar.jsp` (la nota de sustentación es la única del sistema) |
| ESTUDIANTE | Iniciar proyecto y elegir idea | OK | `iniciar-proyecto.jsp`, pestaña "2. Idea" en `entrega.jsp` (Fase 1: elegir del banco o postular su propia idea con `accion=postular`; queda con estado POSTULADA y `propuesta_por` = estudiante, una por equipo; Coordinación la ve, la aprueba o la devuelve desde `atender-solicitud.jsp`) |
| ESTUDIANTE | Trabajar en equipo de 2 | OK | Pestaña "3. Equipo" en `entrega.jsp` (Fase 1, turno Estudiante): el estudiante principal (`estudiante_id`) agrega o quita al compañero (`estudiante2_id`, un solo POST `accion=companero`/`quitar-companero`); ambos ven el mismo proyecto, la misma idea y las mismas entregas; cualquiera de los dos puede enviar la fase, pero solo una persona sube el enlace de cada fase (regla del uploader: mientras un miembro tenga enlaces de la fase, el otro ve la alerta con su nombre y no puede registrar, editar ni eliminar; al eliminarlos la fase se libera, y el reemplazo del profesor también la libera) |
| ESTUDIANTE | Anteproyecto por enlaces | OK | `entrega.jsp` (fases 1/2/4: registrar, editar, eliminar propios, enviar; el envío cuenta los enlaces de ambos integrantes, `enviado_por IN (estudiante_id, estudiante2_id)`; en equipos, solo el uploader de la fase registra: el otro miembro ve la alerta y su POST se rechaza con `error=otro-subio`, inserción atómica `INSERT ... SELECT ... WHERE NOT EXISTS`) |
| PROFESOR | Subir su versión del documento | OK | `entrega.jsp` en su turno (director 2/4 `DIRECTOR`, evaluador 3/5 `EVALUADOR`; solo edita sus enlaces; su versión reemplaza el enlace anterior del hilo 2+3 o 4+5, la fase 1 nunca se toca) + `entrega-eliminar.jsp` + botón “Subir mi versión” en `revisar.jsp`/`evaluar.jsp`; hilos 2+3/4+5 en `evaluar.jsp`/`avalar.jsp` |
| ESTUDIANTE | Ver director y evaluador | OK | Tarjeta Responsables (`entrega.jsp`, incluye Estudiante y Compañero(a)), línea GRA (`seguimiento.jsp`) y tarjeta "Equipo del proyecto" (pestaña "3. Equipo") |
| ESTUDIANTE | Calendario / Formatos | OK | Solo lectura/apertura |
| PROFESOR | Revisar entregas (aprobar/devolver) | OK | `revisar.jsp` (director, fases 2/4) |
| PROFESOR | Ver info del alumno | OK | Tarjeta estudiante en `revisar.jsp` |
| PROFESOR | Aprobar para el evaluador | OK | `revisar.jsp` APROBAR (fase 3/5, `EVALUADOR`) + DEVOLVER |
| PROFESOR | Ver lo aprobado por el director | OK | `evaluar.jsp` (evaluador, enlaces fase 2/4 + última revisión) |
| PROFESOR | Aprobar para aval de coordinación | OK | `evaluar.jsp` APROBAR (misma fase 3/5 → `COORDINACION` pendiente de aval) + DEVOLVER (3→2, 5→4 sin pasar por Coordinación) |
| PROFESOR | Calendario / Formatos | OK | Solo lectura/apertura |

**Resultado: ningún requerimiento marcado como FALTA.**

## 4. Observaciones menores (no requeridas, fuera de alcance)

- `entrega.jsp` muestra el historial con autor e insignia de rol; cada quien solo edita o elimina sus enlaces (y en equipos de 2, solo el uploader de la fase registra enlaces nuevos).
- Equipos de 2: cuando el proyecto tiene compañero, todas las vistas de detalle (proyecto-ver, seguimiento, entrega, revisar, evaluar, avalar, atender-solicitud, sustentación, informes) lo muestran con su nombre y código; el compañero pierde el acceso si se le quita del equipo y puede iniciar su propio proyecto.
- Regla "solo una persona sube el enlace de cada fase" (equipos de 2): el uploader es el miembro con enlaces en la fase 1/2/4 (`enviado_por IN (estudiante_id, estudiante2_id)`); el otro miembro ve una alerta con su nombre ("<nombre> ya subió el enlace de esta fase...") sin formulario ni botones, y el servidor rechaza su POST (`error=otro-subio`). Si el uploader elimina todos sus enlaces de la fase — o un profesor reemplaza el documento, que borra el hilo 2+3/4+5 — la fase queda libre y cualquiera de los dos puede subir. En un proyecto sin compañero nada cambia.
