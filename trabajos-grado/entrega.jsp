<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  entrega.jsp (alcance por rol, igual que proyecto-ver.jsp)
  Historial de entregas por ENLACE de la fase N (sin subida de archivos).
  Pueden registrar enlaces en la fase consultada (= fase actual):
  - ESTUDIANTE (cualquier miembro del equipo): fase 1, 2 o 4 con estado 'ESTUDIANTE'.
  - PROFESOR director: fase 2 o 4 con estado 'DIRECTOR'.
  - PROFESOR evaluador: fase 3 o 5 con estado 'EVALUADOR'.
  Solo se edita/elimina lo propio (enviado_por = usuario).
  Pestaña "3. Equipo" en Fase 1: el estudiante principal agrega o quita
  al companero (estudiante2_id) mientras la fase siga en 'ESTUDIANTE'.
  No cambia fase ni estado del anteproyecto.
--%>
<%@ include file="includes/guard.jspf" %>

<c:set var="activo" value="proyectos" scope="request" />
<c:set var="titulo" value="Entrega de la FASE ${param.fase}" scope="request" />
<c:import url="includes/conexion.jsp" />

<c:if test="${empty param.id}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:if test="${param.fase != '1' and param.fase != '2' and param.fase != '3' and param.fase != '4' and param.fase != '5'}">
  <c:redirect url="seguimiento.jsp?id=${param.id}" />
</c:if>
<c:catch var="dbError">
  <sql:query var="ver" dataSource="${db}">
    SELECT a.id, a.codigo, a.fase, a.estado, a.estudiante_id, a.estudiante2_id, a.director_id, a.evaluador_id, a.obs_coordinacion,
           (SELECT u3.nombre FROM usuarios u3 WHERE u3.id = a.estudiante_id) AS est_nombre,
           (SELECT u3.codigo FROM usuarios u3 WHERE u3.id = a.estudiante_id) AS est_codigo,
           (SELECT u3.correo FROM usuarios u3 WHERE u3.id = a.estudiante_id) AS est_correo,
           (SELECT u4.nombre FROM usuarios u4 WHERE u4.id = a.estudiante2_id) AS est2_nombre,
           (SELECT u4.codigo FROM usuarios u4 WHERE u4.id = a.estudiante2_id) AS est2_codigo,
           (SELECT u4.correo FROM usuarios u4 WHERE u4.id = a.estudiante2_id) AS est2_correo,
           (SELECT d2.nombre FROM usuarios d2 WHERE d2.id = a.director_id) AS dir_nombre,
           (SELECT d2.correo FROM usuarios d2 WHERE d2.id = a.director_id) AS dir_correo,
           (SELECT v2.nombre FROM usuarios v2 WHERE v2.id = a.evaluador_id) AS eva_nombre,
           (SELECT v2.correo FROM usuarios v2 WHERE v2.id = a.evaluador_id) AS eva_correo,
           (SELECT COUNT(*) FROM entregas e2 WHERE e2.anteproyecto_id = a.id
             AND ((a.fase IN ('2', '3') AND e2.fase IN ('2', '3'))
               OR (a.fase IN ('4', '5') AND e2.fase IN ('4', '5')))) AS hilo_n
    FROM anteproyectos a
    WHERE a.id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${empty dbError and ver.rowCount == 0}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>

<%-- Control de alcance por rol --%>
<c:set var="autorizado" value="false" />
<c:set var="esMiembro" value="${sessionScope.rol == 'ESTUDIANTE'
  and (ver.rows[0].estudiante_id == sessionScope.usuarioId or ver.rows[0].estudiante2_id == sessionScope.usuarioId)}" />
<c:if test="${sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR'}">
  <c:set var="autorizado" value="true" />
</c:if>
<c:if test="${esMiembro}">
  <c:set var="autorizado" value="true" />
</c:if>
<c:if test="${sessionScope.rol == 'PROFESOR' and (ver.rows[0].director_id == sessionScope.usuarioId or ver.rows[0].evaluador_id == sessionScope.usuarioId)}">
  <c:set var="autorizado" value="true" />
</c:if>
<c:if test="${empty dbError and ver.rowCount == 1 and not autorizado}">
  <c:redirect url="acceso-denegado.jsp" />
</c:if>

<%-- Equipo (pestaña "3. Equipo"): el principal gestiona mientras la fase 1 siga abierta --%>
<c:set var="esPrincipal" value="${sessionScope.rol == 'ESTUDIANTE' and ver.rows[0].estudiante_id == sessionScope.usuarioId}" />
<c:set var="esCompanero" value="${sessionScope.rol == 'ESTUDIANTE' and ver.rows[0].estudiante2_id == sessionScope.usuarioId}" />
<c:set var="equipoAbierto" value="${ver.rows[0].fase == '1' and ver.rows[0].estado == 'ESTUDIANTE'}" />
<c:set var="gestionaEquipo" value="${esPrincipal and equipoAbierto}" />

<%-- ¿Quién puede registrar? Estudiante miembro del equipo (1/2/4 + ESTUDIANTE), director (2/4 + DIRECTOR) o evaluador (3/5 + EVALUADOR), siempre en la fase actual --%>
<c:set var="puedeEnviarEst" value="${esMiembro
  and (param.fase == '1' or param.fase == '2' or param.fase == '4')
  and param.fase == ver.rows[0].fase
  and ver.rows[0].estado == 'ESTUDIANTE'}" />
<c:set var="puedeSubirDir" value="${sessionScope.rol == 'PROFESOR'
  and ver.rows[0].director_id == sessionScope.usuarioId
  and (ver.rows[0].fase == '2' or ver.rows[0].fase == '4')
  and param.fase == ver.rows[0].fase
  and ver.rows[0].estado == 'DIRECTOR'}" />
<c:set var="puedeSubirEva" value="${sessionScope.rol == 'PROFESOR'
  and ver.rows[0].evaluador_id == sessionScope.usuarioId
  and (ver.rows[0].fase == '3' or ver.rows[0].fase == '5')
  and param.fase == ver.rows[0].fase
  and ver.rows[0].estado == 'EVALUADOR'}" />
<c:set var="puedeEnviar" value="${puedeEnviarEst or puedeSubirDir or puedeSubirEva}" />
<c:set var="esVersionProfesor" value="${puedeSubirDir or puedeSubirEva}" />

<%-- Hilo del documento: fases 2+3 (propuesta) o 4+5 (informe); la fase 1 nunca se toca --%>
<c:set var="hiloA" value="4" />
<c:set var="hiloB" value="5" />
<c:if test="${ver.rows[0].fase == '2' or ver.rows[0].fase == '3'}">
  <c:set var="hiloA" value="2" />
  <c:set var="hiloB" value="3" />
</c:if>
<c:set var="hayHilo" value="${esVersionProfesor and ver.rows[0].hilo_n > 0}" />

<%-- Texto del campo segun la fase y el rol --%>
<c:set var="etiquetaEnlace" value="Enlace" />
<c:if test="${param.fase == '1'}"><c:set var="etiquetaEnlace" value="Enlace del comprobante de pago" /></c:if>
<c:if test="${param.fase == '2'}"><c:set var="etiquetaEnlace" value="Enlace de la propuesta" /></c:if>
<c:if test="${param.fase == '4'}"><c:set var="etiquetaEnlace" value="Enlace del informe" /></c:if>
<c:if test="${esVersionProfesor}"><c:set var="etiquetaEnlace" value="Enlace del documento revisado" /></c:if>

<%-- POST: registrar el enlace (mismo formulario, sin cambiar fase/estado) --%>
<c:if test="${pageContext.request.method == 'POST'}">
  <c:choose>
    <c:when test="${param.accion == 'postular'}">
      <c:choose>
        <c:when test="${not puedeEnviarEst or param.fase != '1'}">
          <c:set var="formError" value="No tiene permiso para postular una idea en esta fase." scope="request" />
        </c:when>
        <c:when test="${empty fn:trim(param.titulo) or empty fn:trim(param.descripcion) or empty fn:trim(param.area)}">
          <c:set var="formError" value="El nombre del proyecto, la descripción y el área son obligatorios." scope="request" />
        </c:when>
        <c:when test="${fn:length(fn:trim(param.titulo)) > 200}">
          <c:set var="formError" value="El nombre del proyecto no puede superar 200 caracteres." scope="request" />
        </c:when>
        <c:when test="${fn:length(fn:trim(param.descripcion)) < 20}">
          <c:set var="formError" value="La descripción debe tener al menos 20 caracteres." scope="request" />
        </c:when>
        <c:when test="${fn:length(fn:trim(param.descripcion)) > 65535}">
          <c:set var="formError" value="La descripción no puede superar 65535 caracteres." scope="request" />
        </c:when>
        <c:when test="${fn:length(fn:trim(param.area)) > 100}">
          <c:set var="formError" value="El área del proyecto no puede superar 100 caracteres." scope="request" />
        </c:when>
        <c:otherwise>
          <c:catch var="postError">
            <sql:query var="solActual" dataSource="${db}">
              SELECT a.idea_solicitada_id, a.estudiante_id, a.estudiante2_id,
                     (SELECT i2.estado FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_estado,
                     (SELECT i2.propuesta_por FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_por
              FROM anteproyectos a WHERE a.id = ?
              <sql:param value="${param.id}" />
            </sql:query>
          </c:catch>
          <c:choose>
            <c:when test="${not empty postError}">
              <c:set var="formError" value="No se pudo guardar tu idea. Intente de nuevo." scope="request" />
            </c:when>
            <c:otherwise>
              <c:set var="actualizarPostulada" value="${solActual.rows[0].sol_estado == 'POSTULADA'
                and (solActual.rows[0].sol_por == solActual.rows[0].estudiante_id or solActual.rows[0].sol_por == solActual.rows[0].estudiante2_id)}" />
              <c:choose>
                <c:when test="${actualizarPostulada}">
                  <c:catch var="updIdeaError">
                    <sql:update var="mIdea" dataSource="${db}">
                      UPDATE ideas SET titulo = ?, descripcion = ?, area = ?
                      WHERE id = ? AND estado = 'POSTULADA' AND propuesta_por IN (?, ?)
                      <sql:param value="${fn:trim(param.titulo)}" />
                      <sql:param value="${fn:trim(param.descripcion)}" />
                      <sql:param value="${fn:trim(param.area)}" />
                      <sql:param value="${solActual.rows[0].idea_solicitada_id}" />
                      <sql:param value="${solActual.rows[0].estudiante_id}" />
                      <sql:param value="${solActual.rows[0].estudiante2_id}" />
                    </sql:update>
                  </c:catch>
                  <c:choose>
                    <c:when test="${empty updIdeaError and mIdea > 0}">
                      <c:redirect url="entrega.jsp?id=${param.id}&fase=1&tab=idea&modo=propia&ok=7" />
                    </c:when>
                    <c:otherwise>
                      <c:set var="formError" value="No se pudo actualizar tu idea. Intente de nuevo." scope="request" />
                    </c:otherwise>
                  </c:choose>
                </c:when>
                <c:otherwise>
                  <c:catch var="postTxError">
                    <sql:transaction dataSource="${db}">
                      <sql:update var="nIdea">
                        INSERT INTO ideas (titulo, descripcion, area, estado, propuesta_por)
                        VALUES (?, ?, ?, 'POSTULADA', ?)
                        <sql:param value="${fn:trim(param.titulo)}" />
                        <sql:param value="${fn:trim(param.descripcion)}" />
                        <sql:param value="${fn:trim(param.area)}" />
                        <sql:param value="${sessionScope.usuarioId}" />
                      </sql:update>
                      <sql:query var="idNueva">
                        SELECT LAST_INSERT_ID() AS id
                      </sql:query>
                      <sql:update var="uSol">
                        UPDATE anteproyectos SET idea_solicitada_id = ?
                        WHERE id = ? AND (estudiante_id = ? OR estudiante2_id = ?) AND fase = '1' AND estado = 'ESTUDIANTE'
                        <sql:param value="${idNueva.rows[0].id}" />
                        <sql:param value="${param.id}" />
                        <sql:param value="${sessionScope.usuarioId}" />
                        <sql:param value="${sessionScope.usuarioId}" />
                      </sql:update>
                    </sql:transaction>
                  </c:catch>
                  <c:choose>
                    <c:when test="${empty postTxError and uSol > 0}">
                      <c:redirect url="entrega.jsp?id=${param.id}&fase=1&tab=idea&modo=propia&ok=7" />
                    </c:when>
                    <c:otherwise>
                      <c:if test="${empty postTxError and uSol == 0}">
                        <c:catch var="limpiarError">
                          <sql:update var="limpiar" dataSource="${db}">
                            DELETE FROM ideas WHERE id = ? AND estado = 'POSTULADA' AND propuesta_por = ?
                            <sql:param value="${idNueva.rows[0].id}" />
                            <sql:param value="${sessionScope.usuarioId}" />
                          </sql:update>
                        </c:catch>
                      </c:if>
                      <c:set var="formError" value="No se pudo guardar tu idea. Intente de nuevo." scope="request" />
                    </c:otherwise>
                  </c:choose>
                </c:otherwise>
              </c:choose>
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:when>
    <c:when test="${param.accion == 'idea'}">
      <c:choose>
        <c:when test="${not puedeEnviarEst or param.fase != '1'}">
          <c:set var="formError" value="No tiene permiso para elegir idea en esta fase." scope="request" />
        </c:when>
        <c:when test="${empty param.idea_id}">
          <c:set var="formError" value="Elija una idea del banco." scope="request" />
        </c:when>
        <c:otherwise>
          <c:catch var="ideaError">
            <sql:query var="elegida" dataSource="${db}">
              SELECT id, estado FROM ideas WHERE id = ?
              <sql:param value="${param.idea_id}" />
            </sql:query>
          </c:catch>
          <c:choose>
            <c:when test="${not empty ideaError or elegida.rowCount == 0 or elegida.rows[0].estado != 'DISPONIBLE'}">
              <c:set var="formError" value="La idea ya no está disponible." scope="request" />
            </c:when>
            <c:otherwise>
              <c:catch var="solActualError">
                <sql:query var="solActual" dataSource="${db}">
                  SELECT a.idea_solicitada_id, a.estudiante_id, a.estudiante2_id,
                         (SELECT i2.estado FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_estado,
                         (SELECT i2.propuesta_por FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_por
                  FROM anteproyectos a WHERE a.id = ?
                  <sql:param value="${param.id}" />
                </sql:query>
              </c:catch>
              <c:choose>
                <c:when test="${not empty solActualError}">
                  <c:set var="formError" value="No se pudo guardar la idea. Intente de nuevo." scope="request" />
                </c:when>
                <c:otherwise>
                  <c:set var="borrarPostulada" value="${solActual.rows[0].sol_estado == 'POSTULADA'
                    and (solActual.rows[0].sol_por == solActual.rows[0].estudiante_id or solActual.rows[0].sol_por == solActual.rows[0].estudiante2_id)}" />
                  <c:catch var="solError">
                    <sql:transaction dataSource="${db}">
                      <sql:update var="s">
                        UPDATE anteproyectos SET idea_solicitada_id = ?
                        WHERE id = ? AND fase = '1' AND estado = 'ESTUDIANTE' AND (estudiante_id = ? OR estudiante2_id = ?)
                        <sql:param value="${param.idea_id}" />
                        <sql:param value="${param.id}" />
                        <sql:param value="${sessionScope.usuarioId}" />
                        <sql:param value="${sessionScope.usuarioId}" />
                      </sql:update>
                      <c:if test="${borrarPostulada}">
                        <sql:update var="d">
                          DELETE FROM ideas WHERE id = ? AND estado = 'POSTULADA' AND propuesta_por IN (?, ?)
                          <sql:param value="${solActual.rows[0].idea_solicitada_id}" />
                          <sql:param value="${solActual.rows[0].estudiante_id}" />
                          <sql:param value="${solActual.rows[0].estudiante2_id}" />
                        </sql:update>
                      </c:if>
                    </sql:transaction>
                  </c:catch>
                  <c:choose>
                    <c:when test="${empty solError and s > 0}">
                      <c:redirect url="entrega.jsp?id=${param.id}&fase=${param.fase}&tab=idea&ok=5" />
                    </c:when>
                    <c:otherwise>
                      <c:set var="formError" value="No se pudo guardar la idea. Intente de nuevo." scope="request" />
                    </c:otherwise>
                  </c:choose>
                </c:otherwise>
              </c:choose>
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:when>
    <c:when test="${param.accion == 'companero'}">
      <c:choose>
        <c:when test="${not gestionaEquipo or not empty ver.rows[0].estudiante2_id}">
          <c:set var="formError" value="No tiene permiso para agregar compañeros en este momento." scope="request" />
        </c:when>
        <c:when test="${empty param.estudiante_id}">
          <c:set var="formError" value="Elija un estudiante para agregar al equipo." scope="request" />
        </c:when>
        <c:otherwise>
          <c:catch var="compError">
            <sql:transaction dataSource="${db}">
              <sql:query var="cand">
                SELECT COUNT(*) AS n FROM usuarios u
                JOIN roles r ON r.id = u.rol_id
                WHERE u.id = ? AND r.nombre = 'ESTUDIANTE' AND u.estado = 'ACTIVO'
                  AND u.id <> ?
                  AND NOT EXISTS (SELECT 1 FROM anteproyectos a2
                                  WHERE (a2.estudiante_id = u.id OR a2.estudiante2_id = u.id)
                                    AND a2.estado <> 'RECHAZADO')
                <sql:param value="${param.estudiante_id}" />
                <sql:param value="${ver.rows[0].estudiante_id}" />
              </sql:query>
              <c:if test="${cand.rows[0].n > 0}">
                <sql:update var="uComp">
                  UPDATE anteproyectos SET estudiante2_id = ?
                  WHERE id = ? AND estudiante_id = ? AND estudiante2_id IS NULL
                    AND fase = '1' AND estado = 'ESTUDIANTE'
                  <sql:param value="${param.estudiante_id}" />
                  <sql:param value="${param.id}" />
                  <sql:param value="${ver.rows[0].estudiante_id}" />
                </sql:update>
              </c:if>
            </sql:transaction>
          </c:catch>
          <c:choose>
            <c:when test="${empty compError and not empty uComp and uComp > 0}">
              <c:redirect url="entrega.jsp?id=${param.id}&amp;fase=1&amp;tab=equipo&amp;ok=8" />
            </c:when>
            <c:otherwise>
              <c:set var="formError" value="No se pudo agregar al compañero(a). Verifique que el estudiante esté activo y sin proyecto." scope="request" />
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:when>
    <c:when test="${param.accion == 'quitar-companero'}">
      <c:choose>
        <c:when test="${not gestionaEquipo or empty ver.rows[0].estudiante2_id}">
          <c:set var="formError" value="No tiene permiso para quitar compañeros en este momento." scope="request" />
        </c:when>
        <c:otherwise>
          <c:catch var="quitError">
            <sql:update var="q" dataSource="${db}">
              UPDATE anteproyectos SET estudiante2_id = NULL
              WHERE id = ? AND estudiante_id = ? AND estudiante2_id IS NOT NULL
                AND fase = '1' AND estado = 'ESTUDIANTE'
              <sql:param value="${param.id}" />
              <sql:param value="${ver.rows[0].estudiante_id}" />
            </sql:update>
          </c:catch>
          <c:choose>
            <c:when test="${empty quitError and q > 0}">
              <c:redirect url="entrega.jsp?id=${param.id}&amp;fase=1&amp;tab=equipo&amp;ok=9" />
            </c:when>
            <c:otherwise>
              <c:set var="formError" value="No se pudo quitar al compañero(a). Intente de nuevo." scope="request" />
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:when>
    <c:when test="${not puedeEnviar}">
      <c:set var="formError" value="No tiene permiso para enviar en esta fase." scope="request" />
    </c:when>
    <c:when test="${empty param.enlace}">
      <c:set var="formError" value="El enlace es obligatorio." scope="request" />
    </c:when>
    <c:when test="${not fn:startsWith(param.enlace, 'http://') and not fn:startsWith(param.enlace, 'https://')}">
      <c:set var="formError" value="El enlace debe empezar con http:// o https://." scope="request" />
    </c:when>
    <c:when test="${fn:length(param.enlace) > 500}">
      <c:set var="formError" value="El enlace no puede superar 500 caracteres." scope="request" />
    </c:when>
    <c:otherwise>
      <c:choose>
        <c:when test="${not empty param.editar}">
          <c:choose>
            <c:when test="${puedeEnviarEst}">
              <c:catch var="updError">
                <sql:update var="m" dataSource="${db}">
                  UPDATE entregas SET enlace = ?, comentario = ?
                  WHERE id = ? AND anteproyecto_id = ? AND fase = ? AND enviado_por = ?
                    AND EXISTS (SELECT 1 FROM anteproyectos a
                                WHERE a.id = ? AND a.fase = ? AND a.estado = 'ESTUDIANTE'
                                  AND (a.estudiante_id = ? OR a.estudiante2_id = ?))
                  <sql:param value="${param.enlace}" />
                  <sql:param value="${param.comentario}" />
                  <sql:param value="${param.editar}" />
                  <sql:param value="${param.id}" />
                  <sql:param value="${param.fase}" />
                  <sql:param value="${sessionScope.usuarioId}" />
                  <sql:param value="${param.id}" />
                  <sql:param value="${param.fase}" />
                  <sql:param value="${sessionScope.usuarioId}" />
                  <sql:param value="${sessionScope.usuarioId}" />
                </sql:update>
              </c:catch>
            </c:when>
            <c:when test="${puedeSubirDir}">
              <c:catch var="updError">
                <sql:update var="m" dataSource="${db}">
                  UPDATE entregas SET enlace = ?, comentario = ?
                  WHERE id = ? AND anteproyecto_id = ? AND fase = ? AND enviado_por = ?
                    AND EXISTS (SELECT 1 FROM anteproyectos a
                                WHERE a.id = ? AND a.fase = ? AND a.estado = 'DIRECTOR'
                                  AND a.director_id = ? AND a.fase IN ('2', '4'))
                  <sql:param value="${param.enlace}" />
                  <sql:param value="${param.comentario}" />
                  <sql:param value="${param.editar}" />
                  <sql:param value="${param.id}" />
                  <sql:param value="${param.fase}" />
                  <sql:param value="${sessionScope.usuarioId}" />
                  <sql:param value="${param.id}" />
                  <sql:param value="${param.fase}" />
                  <sql:param value="${sessionScope.usuarioId}" />
                </sql:update>
              </c:catch>
            </c:when>
            <c:otherwise>
              <c:catch var="updError">
                <sql:update var="m" dataSource="${db}">
                  UPDATE entregas SET enlace = ?, comentario = ?
                  WHERE id = ? AND anteproyecto_id = ? AND fase = ? AND enviado_por = ?
                    AND EXISTS (SELECT 1 FROM anteproyectos a
                                WHERE a.id = ? AND a.fase = ? AND a.estado = 'EVALUADOR'
                                  AND a.evaluador_id = ? AND a.fase IN ('3', '5'))
                  <sql:param value="${param.enlace}" />
                  <sql:param value="${param.comentario}" />
                  <sql:param value="${param.editar}" />
                  <sql:param value="${param.id}" />
                  <sql:param value="${param.fase}" />
                  <sql:param value="${sessionScope.usuarioId}" />
                  <sql:param value="${param.id}" />
                  <sql:param value="${param.fase}" />
                  <sql:param value="${sessionScope.usuarioId}" />
                </sql:update>
              </c:catch>
            </c:otherwise>
          </c:choose>
          <c:choose>
            <c:when test="${empty updError and m > 0}">
              <c:redirect url="entrega.jsp?id=${param.id}&fase=${param.fase}&ok=2" />
            </c:when>
            <c:otherwise>
              <c:set var="formError" value="No se pudo actualizar. Verifique los datos." scope="request" />
            </c:otherwise>
          </c:choose>
        </c:when>
        <c:otherwise>
          <c:choose>
            <c:when test="${esVersionProfesor}">
              <c:choose>
                <c:when test="${puedeSubirDir}">
                  <c:catch var="insError">
                    <sql:transaction dataSource="${db}">
                      <sql:update var="del">
                        DELETE FROM entregas WHERE anteproyecto_id = ? AND fase IN (?, ?)
                        AND EXISTS (SELECT 1 FROM anteproyectos a
                                    WHERE a.id = ? AND a.fase = ? AND a.estado = 'DIRECTOR'
                                      AND a.director_id = ?)
                        <sql:param value="${param.id}" />
                        <sql:param value="${hiloA}" />
                        <sql:param value="${hiloB}" />
                        <sql:param value="${param.id}" />
                        <sql:param value="${param.fase}" />
                        <sql:param value="${sessionScope.usuarioId}" />
                      </sql:update>
                      <sql:update var="n">
                        INSERT INTO entregas (anteproyecto_id, fase, enlace, comentario, enviado_por)
                        VALUES (?, ?, ?, ?, ?)
                        <sql:param value="${param.id}" />
                        <sql:param value="${param.fase}" />
                        <sql:param value="${param.enlace}" />
                        <sql:param value="${param.comentario}" />
                        <sql:param value="${sessionScope.usuarioId}" />
                      </sql:update>
                    </sql:transaction>
                  </c:catch>
                </c:when>
                <c:otherwise>
                  <c:catch var="insError">
                    <sql:transaction dataSource="${db}">
                      <sql:update var="del">
                        DELETE FROM entregas WHERE anteproyecto_id = ? AND fase IN (?, ?)
                        AND EXISTS (SELECT 1 FROM anteproyectos a
                                    WHERE a.id = ? AND a.fase = ? AND a.estado = 'EVALUADOR'
                                      AND a.evaluador_id = ?)
                        <sql:param value="${param.id}" />
                        <sql:param value="${hiloA}" />
                        <sql:param value="${hiloB}" />
                        <sql:param value="${param.id}" />
                        <sql:param value="${param.fase}" />
                        <sql:param value="${sessionScope.usuarioId}" />
                      </sql:update>
                      <sql:update var="n">
                        INSERT INTO entregas (anteproyecto_id, fase, enlace, comentario, enviado_por)
                        VALUES (?, ?, ?, ?, ?)
                        <sql:param value="${param.id}" />
                        <sql:param value="${param.fase}" />
                        <sql:param value="${param.enlace}" />
                        <sql:param value="${param.comentario}" />
                        <sql:param value="${sessionScope.usuarioId}" />
                      </sql:update>
                    </sql:transaction>
                  </c:catch>
                </c:otherwise>
              </c:choose>
              <c:choose>
                <c:when test="${empty insError}">
                  <c:choose>
                    <c:when test="${del > 0}">
                      <c:redirect url="entrega.jsp?id=${param.id}&fase=${param.fase}&ok=6" />
                    </c:when>
                    <c:otherwise>
                      <c:redirect url="entrega.jsp?id=${param.id}&fase=${param.fase}&ok=1" />
                    </c:otherwise>
                  </c:choose>
                </c:when>
                <c:otherwise>
                  <c:set var="formError" value="No se pudo registrar el enlace. Intente de nuevo." scope="request" />
                </c:otherwise>
              </c:choose>
            </c:when>
            <c:otherwise>
              <%-- Insercion atomica (estudiante): no inserta si el otro miembro ya tiene enlaces en la fase --%>
              <c:catch var="insError">
                <sql:update var="n" dataSource="${db}">
                  INSERT INTO entregas (anteproyecto_id, fase, enlace, comentario, enviado_por)
                  SELECT ?, ?, ?, ?, ?
                  FROM DUAL
                  WHERE NOT EXISTS (
                    SELECT 1 FROM entregas e6
                    JOIN anteproyectos a6 ON a6.id = e6.anteproyecto_id
                    WHERE e6.anteproyecto_id = ? AND e6.fase = ?
                      AND e6.enviado_por = CASE WHEN a6.estudiante_id = ? THEN a6.estudiante2_id ELSE a6.estudiante_id END)
                  <sql:param value="${param.id}" />
                  <sql:param value="${param.fase}" />
                  <sql:param value="${param.enlace}" />
                  <sql:param value="${param.comentario}" />
                  <sql:param value="${sessionScope.usuarioId}" />
                  <sql:param value="${param.id}" />
                  <sql:param value="${param.fase}" />
                  <sql:param value="${sessionScope.usuarioId}" />
                </sql:update>
              </c:catch>
              <c:choose>
                <c:when test="${not empty insError}">
                  <c:set var="formError" value="No se pudo registrar el enlace. Intente de nuevo." scope="request" />
                </c:when>
                <c:when test="${n == 0}">
                  <c:redirect url="entrega.jsp?id=${param.id}&fase=${param.fase}&error=otro-subio" />
                </c:when>
                <c:otherwise>
                  <c:redirect url="entrega.jsp?id=${param.id}&fase=${param.fase}&ok=1" />
                </c:otherwise>
              </c:choose>
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:otherwise>
  </c:choose>
</c:if>

<%-- Edición (?editar=ID): precarga solo si la entrega es propia, del proyecto y fase --%>
<c:set var="esEdicion" value="${not empty param.editar}" />
<c:if test="${esEdicion and puedeEnviar}">
  <c:catch var="editError">
    <sql:query var="editada" dataSource="${db}">
      SELECT id, enlace, comentario FROM entregas
      WHERE id = ? AND anteproyecto_id = ? AND fase = ? AND enviado_por = ?
      <sql:param value="${param.editar}" />
      <sql:param value="${param.id}" />
      <sql:param value="${param.fase}" />
      <sql:param value="${sessionScope.usuarioId}" />
    </sql:query>
  </c:catch>
  <c:if test="${pageContext.request.method != 'POST' and (not empty editError or editada.rowCount == 0)}">
    <c:redirect url="entrega.jsp?id=${param.id}&fase=${param.fase}" />
  </c:if>
</c:if>
<c:set var="tituloForm" value="${esEdicion ? 'Editar enlace' : 'Registrar enlace'}" />
<c:if test="${esVersionProfesor and not esEdicion}"><c:set var="tituloForm" value="Subir mi versión del documento" /></c:if>
<c:if test="${esVersionProfesor and esEdicion}"><c:set var="tituloForm" value="Editar mi versión del documento" /></c:if>

<%-- Historial de entregas de la fase, con autor y rol --%>
<c:catch var="dbError2">
  <sql:query var="historial" dataSource="${db}">
    SELECT e.id, e.enlace, e.comentario, e.fecha_envio, e.enviado_por,
           DATE_FORMAT(e.fecha_envio, '%d/%m/%Y %H:%i') AS fecha_txt,
           (SELECT u2.nombre FROM usuarios u2 WHERE u2.id = e.enviado_por) AS autor,
           (SELECT e6.enviado_por FROM entregas e6
             WHERE e6.anteproyecto_id = e.anteproyecto_id AND e6.fase = e.fase
               AND e6.enviado_por IN (a.estudiante_id, a.estudiante2_id)
             ORDER BY e6.id LIMIT 1) AS uploader_id,
           (SELECT u6.nombre FROM usuarios u6 WHERE u6.id =
              (SELECT e7.enviado_por FROM entregas e7
                WHERE e7.anteproyecto_id = e.anteproyecto_id AND e7.fase = e.fase
                  AND e7.enviado_por IN (a.estudiante_id, a.estudiante2_id)
                ORDER BY e7.id LIMIT 1)) AS uploader_nombre,
           CASE WHEN e.enviado_por = a.estudiante_id THEN 'Estudiante'
                WHEN e.enviado_por = a.estudiante2_id THEN 'Estudiante'
                WHEN e.enviado_por = a.director_id THEN 'Director'
                WHEN e.enviado_por = a.evaluador_id THEN 'Evaluador'
                ELSE 'Otro' END AS rol_autor
    FROM entregas e JOIN anteproyectos a ON a.id = e.anteproyecto_id
    WHERE e.anteproyecto_id = ? AND e.fase = ?
    ORDER BY e.fecha_envio DESC, e.id DESC
    <sql:param value="${param.id}" />
    <sql:param value="${param.fase}" />
  </sql:query>
</c:catch>

<%-- Uploader de la fase: miembro del equipo con enlaces en la fase (solo una persona sube) --%>
<c:set var="uploaderId" value="${historial.rows[0].uploader_id}" />
<c:set var="uploaderNombre" value="${historial.rows[0].uploader_nombre}" />
<c:set var="bloqueaUploader" value="${puedeEnviarEst and not empty uploaderId and uploaderId != sessionScope.usuarioId}" />
<c:set var="muestraNotaUploader" value="${puedeEnviarEst and not empty ver.rows[0].estudiante2_id
  and not empty uploaderId and uploaderId == sessionScope.usuarioId}" />

<%-- Condiciones para "Enviar" (fase 1 a Coordinación, 2/4 al Director con director asignado) --%>
<c:set var="esEnviable" value="${(param.fase == '1' or param.fase == '2' or param.fase == '4')
  and esMiembro
  and param.fase == ver.rows[0].fase
  and ver.rows[0].estado == 'ESTUDIANTE'
  and (param.fase == '1' or not empty ver.rows[0].director_id)}" />
<c:if test="${esEnviable}">
  <c:catch var="dbError3">
    <sql:query var="conteoEnvios" dataSource="${db}">
      SELECT COUNT(*) AS n FROM entregas WHERE anteproyecto_id = ? AND fase = ? AND enviado_por IN (?, ?)
      <sql:param value="${param.id}" />
      <sql:param value="${param.fase}" />
      <sql:param value="${ver.rows[0].estudiante_id}" />
      <sql:param value="${ver.rows[0].estudiante2_id}" />
    </sql:query>
  </c:catch>
  <c:set var="numEntregas" value="${conteoEnvios.rows[0].n}" />
</c:if>
<c:set var="puedeEnviarFase" value="${esEnviable and not empty numEntregas and numEntregas > 0}" />
<c:set var="textoEnviar" value="Enviar a Coordinación" />
<c:if test="${param.fase == '2' or param.fase == '4'}">
  <c:set var="textoEnviar" value="Enviar al Director" />
</c:if>

<%-- Idea solicitada (pestaña Fase 1) e ideas DISPONIBLES del banco --%>
<c:if test="${param.fase == '1'}">
  <c:catch var="dbError5">
    <sql:query var="sol" dataSource="${db}">
      SELECT a.idea_solicitada_id,
             (SELECT i2.titulo FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_titulo,
             (SELECT i2.area FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_area,
             (SELECT i2.descripcion FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_desc,
             (SELECT i2.estado FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_estado,
             (SELECT i2.propuesta_por FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_por
      FROM anteproyectos a WHERE a.id = ?
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${param.tab == 'idea' and puedeEnviarEst}">
    <c:catch var="dbError6">
      <sql:query var="banco" dataSource="${db}">
        SELECT id, titulo, area, descripcion FROM ideas
        WHERE estado = 'DISPONIBLE' ORDER BY titulo
      </sql:query>
    </c:catch>
  </c:if>
</c:if>
<c:set var="ideaElegida" value="${sol.rows[0].idea_solicitada_id}" />
<c:set var="postuladaPropia" value="${sol.rows[0].sol_estado == 'POSTULADA' and (sol.rows[0].sol_por == ver.rows[0].estudiante_id or sol.rows[0].sol_por == ver.rows[0].estudiante2_id)}" />
<c:set var="ideaValida" value="${not empty ideaElegida and (sol.rows[0].sol_estado == 'DISPONIBLE' or postuladaPropia)}" />
<c:set var="fPTitulo" value="${postuladaPropia ? sol.rows[0].sol_titulo : ''}" />
<c:set var="fPDescripcion" value="${postuladaPropia ? sol.rows[0].sol_desc : ''}" />
<c:set var="fPArea" value="${postuladaPropia ? sol.rows[0].sol_area : ''}" />
<c:if test="${pageContext.request.method == 'POST' and param.accion == 'postular'}">
  <c:set var="fPTitulo" value="${param.titulo}" />
  <c:set var="fPDescripcion" value="${param.descripcion}" />
  <c:set var="fPArea" value="${param.area}" />
</c:if>
<c:set var="cumpleEnvio" value="${puedeEnviarFase}" />
<c:if test="${param.fase == '1'}">
  <c:set var="cumpleEnvio" value="${puedeEnviarFase and ideaValida}" />
</c:if>

<%-- Última devolución de la fase vigente, del director o del evaluador --%>
<c:if test="${esMiembro and ver.rows[0].estado == 'ESTUDIANTE' and param.fase == ver.rows[0].fase}">
  <c:catch var="dbError4">
    <sql:query var="ultima" dataSource="${db}">
      SELECT observaciones, decision, fecha, 'Director' AS origen FROM revisiones
      WHERE anteproyecto_id = ?
      UNION ALL
      SELECT observaciones, decision, fecha, 'Evaluador' FROM evaluaciones
      WHERE anteproyecto_id = ?
      ORDER BY fecha DESC LIMIT 1
      <sql:param value="${param.id}" />
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
</c:if>
<c:set var="devuelta" value="${not empty ultima and ultima.rowCount > 0 and ultima.rows[0].decision == 'DEVUELTO'}" />

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<c:url var="urlVolver" value="seguimiento.jsp">
  <c:param name="id" value="${param.id}" />
</c:url>

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Entrega de la <span class="badge-lima">FASE ${fn:escapeXml(param.fase)}</span></h4>
      <a href="${urlVolver}" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />
    <p class="text-muted">Proyecto <strong><c:out value="${ver.rows[0].codigo}" /></strong></p>

    <c:if test="${param.ok == 1}">
      <div class="alert alert-success py-2" role="alert">Enlace registrado.</div>
    </c:if>
    <c:if test="${param.ok == 2}">
      <div class="alert alert-success py-2" role="alert">Enlace actualizado.</div>
    </c:if>
    <c:if test="${param.ok == 3}">
      <div class="alert alert-success py-2" role="alert">Enlace eliminado.</div>
    </c:if>
    <c:if test="${param.ok == 4}">
      <div class="alert alert-success py-2" role="alert">Proyecto iniciado. Registra tu enlace de pago y elige tu idea.</div>
    </c:if>
    <c:if test="${param.ok == 5}">
      <div class="alert alert-success py-2" role="alert">Idea guardada.</div>
    </c:if>
    <c:if test="${param.ok == 6}">
      <div class="alert alert-success py-2" role="alert">Tu versión reemplazó el enlace anterior.</div>
    </c:if>
    <c:if test="${param.ok == 7}">
      <div class="alert alert-success py-2" role="alert">Tu idea fue postulada.</div>
    </c:if>
    <c:if test="${param.ok == 8}">
      <div class="alert alert-success py-2" role="alert">Compañero agregado al equipo.</div>
    </c:if>
    <c:if test="${param.ok == 9}">
      <div class="alert alert-success py-2" role="alert">Compañero eliminado del equipo.</div>
    </c:if>
    <c:if test="${param.error == 'invalido'}">
      <div class="alert alert-danger py-2" role="alert">No se pudo procesar la solicitud. Verifique los datos.</div>
    </c:if>
    <c:if test="${param.error == 'otro-subio'}">
      <div class="alert alert-danger py-2" role="alert">Tu compañero(a) ya subió el enlace de esta fase.</div>
    </c:if>
    <c:if test="${not empty requestScope.formError}">
      <div class="alert alert-danger py-2" role="alert"><c:out value="${requestScope.formError}" /></div>
    </c:if>
    <c:if test="${not empty dbError or not empty dbError2}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>
    <c:if test="${devuelta}">
      <div class="alert alert-warning py-2" role="alert">
        Tu <c:out value="${fn:toLowerCase(ultima.rows[0].origen)}" /> devolvi&oacute; esta entrega.
        <c:out value="${ultima.rows[0].observaciones}" />
      </div>
    </c:if>
    <c:if test="${esMiembro and param.fase == '1' and ver.rows[0].estado == 'ESTUDIANTE' and not empty ver.rows[0].obs_coordinacion}">
      <div class="alert alert-warning py-2" role="alert">
        Coordinaci&oacute;n devolvi&oacute; tu solicitud.
        <c:out value="${ver.rows[0].obs_coordinacion}" />
      </div>
    </c:if>

    <c:if test="${param.fase == '1'}">
      <c:url var="urlTabPago" value="entrega.jsp">
        <c:param name="id" value="${param.id}" />
        <c:param name="fase" value="${param.fase}" />
      </c:url>
      <c:url var="urlTabIdea" value="entrega.jsp">
        <c:param name="id" value="${param.id}" />
        <c:param name="fase" value="${param.fase}" />
        <c:param name="tab" value="idea" />
      </c:url>
      <c:url var="urlTabEquipo" value="entrega.jsp">
        <c:param name="id" value="${param.id}" />
        <c:param name="fase" value="${param.fase}" />
        <c:param name="tab" value="equipo" />
      </c:url>
      <ul class="nav nav-tabs mb-3">
        <li class="nav-item"><a class="nav-link ${param.tab == 'idea' or param.tab == 'equipo' ? '' : 'active'}" href="${urlTabPago}">1. Enlace de pago</a></li>
        <li class="nav-item"><a class="nav-link ${param.tab == 'idea' ? 'active' : ''}" href="${urlTabIdea}">2. Idea</a></li>
        <li class="nav-item"><a class="nav-link ${param.tab == 'equipo' ? 'active' : ''}" href="${urlTabEquipo}">3. Equipo</a></li>
      </ul>
    </c:if>

    <c:if test="${param.fase != '1' or (param.tab != 'idea' and param.tab != 'equipo')}">
    <c:if test="${muestraNotaUploader}">
      <p class="small text-muted mb-1"><i class="fa-solid fa-circle-info"></i> Tú subes el enlace de esta fase por tu equipo.</p>
    </c:if>
    <c:if test="${bloqueaUploader}">
      <div class="alert alert-info py-2" role="alert">
        <c:out value="${uploaderNombre}" /> ya subió el enlace de esta fase. Solo una persona del equipo puede subirlo.
        Si <c:out value="${uploaderNombre}" /> elimina sus enlaces de esta fase, podrás subirlo tú.
      </div>
    </c:if>
    <c:if test="${puedeEnviar and not bloqueaUploader}">
      <c:url var="urlBase" value="entrega.jsp">
        <c:param name="id" value="${param.id}" />
        <c:param name="fase" value="${param.fase}" />
      </c:url>
      <c:set var="fEnlace" value="${param.enlace}" />
      <c:set var="fComentario" value="${param.comentario}" />
      <c:if test="${esEdicion and pageContext.request.method != 'POST'}">
        <c:set var="fEnlace" value="${editada.rows[0].enlace}" />
        <c:set var="fComentario" value="${editada.rows[0].comentario}" />
      </c:if>
      <h5><c:out value="${tituloForm}" /></h5>
      <c:if test="${hayHilo and not esEdicion}">
        <div class="alert alert-info py-2" role="alert">El enlace que subas reemplazará al enlace actual del documento.</div>
      </c:if>
      <form method="post" action="entrega.jsp" class="mb-4" id="formEnlace">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
        <input type="hidden" name="fase" value="${fn:escapeXml(param.fase)}" />
        <c:if test="${esEdicion}">
          <input type="hidden" name="editar" value="${fn:escapeXml(param.editar)}" />
        </c:if>
        <div class="row g-3">
          <div class="col-12">
            <label class="form-label" for="enlace"><c:out value="${etiquetaEnlace}" /></label>
            <input type="url" class="form-control" id="enlace" name="enlace" required="required"
                   maxlength="500" placeholder="https://..."
                   value="${fn:escapeXml(fEnlace)}" />
          </div>
          <div class="col-12">
            <label class="form-label" for="comentario">Comentario (opcional)</label>
            <textarea class="form-control" id="comentario" name="comentario" rows="2"
                      placeholder="Comentario opcional"><c:out value="${fComentario}" /></textarea>
          </div>
        </div>
        <div class="mt-3 d-flex gap-2">
          <c:choose>
            <c:when test="${hayHilo and not esEdicion}">
              <button type="button" class="btn btn-lima" data-bs-toggle="modal" data-bs-target="#modalReemplazar"><i class="fa-solid fa-link"></i> Subir y reemplazar</button>
            </c:when>
            <c:otherwise>
              <button type="submit" class="btn btn-lima"><i class="fa-solid fa-link"></i> ${esEdicion ? 'Actualizar' : (esVersionProfesor ? 'Subir' : 'Registrar enlace')}</button>
            </c:otherwise>
          </c:choose>
          <c:if test="${esEdicion}">
            <a href="${urlBase}" class="btn btn-outline-secondary">Cancelar</a>
          </c:if>
        </div>
      </form>
      <c:if test="${hayHilo and not esEdicion}">
        <div class="modal fade" id="modalReemplazar" tabindex="-1" aria-hidden="true">
          <div class="modal-dialog">
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title">Confirmar reemplazo</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
              </div>
              <div class="modal-body">
                Se eliminará el enlace actual del documento y quedará solo el nuevo. ¿Continuar?
                <c:if test="${not empty historial.rows}">
                  <p class="mb-0 mt-2 text-muted">Actual: <c:out value="${historial.rows[0].enlace}" /></p>
                </c:if>
              </div>
              <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                <button type="submit" form="formEnlace" class="btn btn-lima">Confirmar</button>
              </div>
            </div>
          </div>
        </div>
      </c:if>
    </c:if>
    </c:if>

    <h5>Responsables</h5>
    <div class="row g-3 mb-3">
      <div class="col-md-6">
        <div class="card h-100">
          <div class="card-header"><i class="fa-solid fa-user-graduate"></i> Estudiante</div>
          <div class="card-body py-2">
            <c:choose>
              <c:when test="${not empty ver.rows[0].est_nombre}">
                <p class="mb-1"><strong><c:out value="${ver.rows[0].est_nombre}" /></strong>
                  <c:if test="${not empty ver.rows[0].est_codigo}">
                    (<c:out value="${ver.rows[0].est_codigo}" />)
                  </c:if>
                </p>
                <p class="mb-0 text-muted"><c:out value="${ver.rows[0].est_correo}" /></p>
                <c:if test="${not empty ver.rows[0].est2_nombre}">
                  <hr class="my-2" />
                  <p class="mb-0">
                    <span class="badge text-bg-info">Compañero(a)</span>
                    <strong><c:out value="${ver.rows[0].est2_nombre}" /></strong>
                    <c:if test="${not empty ver.rows[0].est2_codigo}">
                      (<c:out value="${ver.rows[0].est2_codigo}" />)
                    </c:if>
                  </p>
                </c:if>
              </c:when>
              <c:otherwise>
                <p class="mb-0 text-muted">Sin asignar</p>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
      </div>
      <div class="col-md-6">
        <div class="card h-100">
          <div class="card-header"><i class="fa-solid fa-chalkboard-user"></i> Director</div>
          <div class="card-body py-2">
            <c:choose>
              <c:when test="${not empty ver.rows[0].dir_nombre}">
                <p class="mb-1"><strong><c:out value="${ver.rows[0].dir_nombre}" /></strong></p>
                <p class="mb-0 text-muted"><c:out value="${ver.rows[0].dir_correo}" /></p>
              </c:when>
              <c:otherwise>
                <p class="mb-0 text-muted">Sin asignar</p>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
      </div>
      <div class="col-md-6">
        <div class="card h-100">
          <div class="card-header"><i class="fa-solid fa-clipboard-check"></i> Evaluador</div>
          <div class="card-body py-2">
            <c:choose>
              <c:when test="${not empty ver.rows[0].eva_nombre}">
                <p class="mb-1"><strong><c:out value="${ver.rows[0].eva_nombre}" /></strong></p>
                <p class="mb-0 text-muted"><c:out value="${ver.rows[0].eva_correo}" /></p>
              </c:when>
              <c:otherwise>
                <p class="mb-0 text-muted">Sin asignar</p>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
      </div>
    </div>

    <c:if test="${param.fase != '1' or (param.tab != 'idea' and param.tab != 'equipo')}">
    <h5>Historial</h5>
    <c:if test="${empty historial.rows}">
      <p class="text-muted">A&uacute;n no hay entregas.</p>
    </c:if>
    <c:forEach var="h" items="${historial.rows}">
      <div class="card mb-2">
        <div class="card-body py-2">
          <p class="mb-1">
            <i class="fa-solid fa-link"></i>
            <a href="${fn:escapeXml(h.enlace)}" target="_blank" rel="noopener"><c:out value="${h.enlace}" /></a>
          </p>
          <c:if test="${not empty h.comentario}">
            <p class="mb-1"><c:out value="${h.comentario}" /></p>
          </c:if>
          <small class="text-muted">
            Subido por <c:out value="${h.autor}" default="&#8212;" />
            <span class="badge text-bg-secondary"><c:out value="${h.rol_autor}" /></span>
            el <c:out value="${h.fecha_txt}" />
          </small>
          <c:if test="${puedeEnviar and h.enviado_por == sessionScope.usuarioId and not bloqueaUploader}">
            <div class="mt-2 d-flex gap-2">
              <c:url var="urlEditar" value="entrega.jsp">
                <c:param name="id" value="${param.id}" />
                <c:param name="fase" value="${param.fase}" />
                <c:param name="editar" value="${h.id}" />
              </c:url>
              <a href="${urlEditar}" class="btn btn-sm btn-lima" title="Editar"><i class="fa-solid fa-pen"></i></a>
              <button type="button" class="btn btn-sm btn-danger" title="Eliminar"
                      data-bs-toggle="modal" data-bs-target="#modalEliminar${h.id}"><i class="fa-solid fa-trash"></i></button>
            </div>
            <div class="modal fade" id="modalEliminar${h.id}" tabindex="-1" aria-hidden="true">
              <div class="modal-dialog">
                <div class="modal-content">
                  <div class="modal-header">
                    <h5 class="modal-title">Confirmar eliminaci&oacute;n</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                  </div>
                  <div class="modal-body">
                    &iquest;Eliminar este enlace?
                  </div>
                  <div class="modal-footer">
                    <form method="post" action="entrega-eliminar.jsp">
                      <input type="hidden" name="id" value="${h.id}" />
                      <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                      <button type="submit" class="btn btn-danger">Eliminar</button>
                    </form>
                  </div>
                </div>
              </div>
            </div>
          </c:if>
        </div>
      </div>
    </c:forEach>
    </c:if>

    <c:if test="${param.fase == '1' and param.tab == 'idea'}">
      <h5>Idea</h5>
      <c:choose>
        <c:when test="${puedeEnviarEst}">
          <c:url var="urlModoBanco" value="entrega.jsp">
            <c:param name="id" value="${param.id}" />
            <c:param name="fase" value="${param.fase}" />
            <c:param name="tab" value="idea" />
            <c:param name="modo" value="banco" />
          </c:url>
          <c:url var="urlModoPropia" value="entrega.jsp">
            <c:param name="id" value="${param.id}" />
            <c:param name="fase" value="${param.fase}" />
            <c:param name="tab" value="idea" />
            <c:param name="modo" value="propia" />
          </c:url>
          <ul class="nav nav-pills mb-3">
            <li class="nav-item"><a class="nav-link ${param.modo == 'propia' ? '' : 'active'}" href="${urlModoBanco}">Elegir del banco</a></li>
            <li class="nav-item"><a class="nav-link ${param.modo == 'propia' ? 'active' : ''}" href="${urlModoPropia}">Postular mi idea</a></li>
          </ul>
          <c:choose>
            <c:when test="${param.modo == 'propia'}">
              <p class="text-muted">Si ninguna idea del banco te convence, puedes postular la tuya. Coordinación la revisará junto con tu solicitud.</p>
              <c:if test="${postuladaPropia}">
                <p><span class="badge-lima">Idea postulada por ti</span></p>
              </c:if>
              <form method="post" action="entrega.jsp">
                <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
                <input type="hidden" name="fase" value="${fn:escapeXml(param.fase)}" />
                <input type="hidden" name="tab" value="idea" />
                <input type="hidden" name="modo" value="propia" />
                <input type="hidden" name="accion" value="postular" />
                <div class="row g-3">
                  <div class="col-12">
                    <label class="form-label" for="nombreProyecto">Nombre del proyecto</label>
                    <input type="text" class="form-control" id="nombreProyecto" name="titulo" required="required"
                           maxlength="200" placeholder="Nombre del proyecto" value="${fn:escapeXml(fPTitulo)}" />
                  </div>
                  <div class="col-12">
                    <label class="form-label" for="descripcionPostulada">Descripción</label>
                    <textarea class="form-control" id="descripcionPostulada" name="descripcion" rows="4" required="required"
                              minlength="20" maxlength="65535"
                              placeholder="Describe tu idea (mínimo 20 caracteres)"><c:out value="${fPDescripcion}" /></textarea>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label" for="areaPostulada">Área del proyecto</label>
                    <input type="text" class="form-control" id="areaPostulada" name="area" required="required"
                           maxlength="100" placeholder="Ej: Inteligencia artificial" value="${fn:escapeXml(fPArea)}" />
                  </div>
                </div>
                <div class="mt-3">
                  <button type="submit" class="btn btn-lima"><i class="fa-solid fa-lightbulb"></i> ${postuladaPropia ? 'Guardar cambios' : 'Postular mi idea'}</button>
                </div>
              </form>
            </c:when>
            <c:otherwise>
              <c:if test="${empty banco.rows}">
                <div class="alert alert-warning py-2" role="alert">No hay ideas disponibles por ahora.</div>
              </c:if>
              <c:if test="${not empty banco.rows}">
                <form method="post" action="entrega.jsp" id="formIdeaBanco">
                  <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
                  <input type="hidden" name="fase" value="${fn:escapeXml(param.fase)}" />
                  <input type="hidden" name="tab" value="idea" />
                  <input type="hidden" name="accion" value="idea" />
                  <div class="row g-3">
                    <c:forEach var="b" items="${banco.rows}">
                      <div class="col-md-6">
                        <div class="card h-100">
                          <div class="card-body">
                            <div class="form-check">
                              <input class="form-check-input" type="radio" name="idea_id" id="idea${b.id}" value="${b.id}" ${b.id == ideaElegida ? 'checked' : ''} required="required" />
                              <label class="form-check-label" for="idea${b.id}"><strong><c:out value="${b.titulo}" /></strong></label>
                            </div>
                            <p class="mb-1 text-muted"><c:out value="${b.area}" default="&#8212;" /></p>
                            <p class="mb-0"><c:out value="${fn:substring(b.descripcion, 0, 120)}" /><c:if test="${fn:length(b.descripcion) > 120}">...</c:if></p>
                          </div>
                        </div>
                      </div>
                    </c:forEach>
                  </div>
                  <div class="mt-3">
                    <c:choose>
                      <c:when test="${postuladaPropia}">
                        <button type="button" class="btn btn-lima" data-bs-toggle="modal" data-bs-target="#modalCambiarIdea"><i class="fa-solid fa-floppy-disk"></i> Guardar idea</button>
                      </c:when>
                      <c:otherwise>
                        <button type="submit" class="btn btn-lima"><i class="fa-solid fa-floppy-disk"></i> Guardar idea</button>
                      </c:otherwise>
                    </c:choose>
                  </div>
                </form>
                <c:if test="${postuladaPropia}">
                  <div class="modal fade" id="modalCambiarIdea" tabindex="-1" aria-hidden="true">
                    <div class="modal-dialog">
                      <div class="modal-content">
                        <div class="modal-header">
                          <h5 class="modal-title">Confirmar cambio</h5>
                          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                        </div>
                        <div class="modal-body">
                          Se eliminará tu idea postulada y se usará la idea del banco que elegiste. ¿Continuar?
                        </div>
                        <div class="modal-footer">
                          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                          <button type="submit" form="formIdeaBanco" class="btn btn-lima">Confirmar</button>
                        </div>
                      </div>
                    </div>
                  </div>
                </c:if>
              </c:if>
            </c:otherwise>
          </c:choose>
        </c:when>
        <c:otherwise>
          <c:choose>
            <c:when test="${not empty ideaElegida}">
              <dl class="row mb-0">
                <dt class="col-sm-3">T&iacute;tulo</dt>
                <dd class="col-sm-9">
                  <c:out value="${sol.rows[0].sol_titulo}" />
                  <c:if test="${sol.rows[0].sol_estado == 'POSTULADA'}">
                    <span class="badge text-bg-info">Propuesta por el estudiante</span>
                  </c:if>
                </dd>
                <dt class="col-sm-3">&Aacute;rea</dt>
                <dd class="col-sm-9"><c:out value="${sol.rows[0].sol_area}" default="&#8212;" /></dd>
                <dt class="col-sm-3">Descripci&oacute;n</dt>
                <dd class="col-sm-9"><c:out value="${sol.rows[0].sol_desc}" /></dd>
                <dt class="col-sm-3">Estado</dt>
                <dd class="col-sm-9"><span class="badge text-bg-secondary"><c:out value="${sol.rows[0].sol_estado}" /></span></dd>
              </dl>
            </c:when>
            <c:otherwise>
              <p class="text-muted">Sin idea elegida.</p>
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:if>

    <c:if test="${param.fase == '1' and param.tab == 'equipo'}">
      <h5>Equipo del proyecto</h5>
      <div class="card mb-3">
        <div class="card-header"><i class="fa-solid fa-people-group"></i> Equipo del proyecto</div>
        <div class="card-body py-2">
          <p class="mb-1">
            <span class="badge-lima">Principal</span>
            <strong><c:out value="${ver.rows[0].est_nombre}" /></strong>
            <c:if test="${not empty ver.rows[0].est_codigo}"> (<c:out value="${ver.rows[0].est_codigo}" />)</c:if>
          </p>
          <p class="mb-0 text-muted"><c:out value="${ver.rows[0].est_correo}" /></p>
          <c:choose>
            <c:when test="${not empty ver.rows[0].estudiante2_id}">
              <hr class="my-2" />
              <p class="mb-1">
                <span class="badge text-bg-info">Compañero(a)</span>
                <strong><c:out value="${ver.rows[0].est2_nombre}" /></strong>
                <c:if test="${not empty ver.rows[0].est2_codigo}"> (<c:out value="${ver.rows[0].est2_codigo}" />)</c:if>
              </p>
              <p class="mb-0 text-muted"><c:out value="${ver.rows[0].est2_correo}" /></p>
            </c:when>
            <c:otherwise>
              <p class="mb-0 text-muted">Sin compañero(a) todavía.</p>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <c:if test="${esCompanero}">
        <div class="alert alert-info py-2" role="alert">Estás en el equipo de <strong><c:out value="${ver.rows[0].est_nombre}" /></strong>.</div>
      </c:if>

      <c:if test="${gestionaEquipo and empty ver.rows[0].estudiante2_id}">
        <h5 class="mt-3">Agregar compañero(a)</h5>
        <form method="get" action="entrega.jsp" class="tabla-toolbar mb-3">
          <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
          <input type="hidden" name="fase" value="1" />
          <input type="hidden" name="tab" value="equipo" />
          <div class="d-flex align-items-center gap-2">
            <label for="q" class="text-nowrap">Buscar:</label>
            <input type="search" id="q" name="q" class="form-control form-control-sm"
                   placeholder="Buscar estudiante por nombre, código o correo" value="${fn:escapeXml(param.q)}" />
            <button type="submit" class="btn btn-sm btn-lima text-nowrap">Buscar</button>
          </div>
        </form>
        <c:set var="qEquipo" value="${fn:trim(param.q)}" />
        <c:if test="${not empty qEquipo and fn:length(qEquipo) < 2}">
          <div class="alert alert-warning py-2" role="alert">Escribe al menos 2 caracteres para buscar.</div>
        </c:if>
        <c:if test="${fn:length(qEquipo) >= 2}">
          <c:set var="patronEquipo" value="%${qEquipo}%" />
          <c:catch var="dbError7">
            <sql:query var="candidatos" dataSource="${db}">
              SELECT u.id, u.nombre, u.codigo FROM usuarios u
              JOIN roles r ON r.id = u.rol_id
              WHERE r.nombre = 'ESTUDIANTE' AND u.estado = 'ACTIVO'
                AND u.id <> ?
                AND NOT EXISTS (SELECT 1 FROM anteproyectos a2
                                WHERE (a2.estudiante_id = u.id OR a2.estudiante2_id = u.id)
                                  AND a2.estado <> 'RECHAZADO')
                AND (u.nombre LIKE ? OR COALESCE(u.codigo, '') LIKE ? OR u.correo LIKE ?)
              ORDER BY u.nombre LIMIT 11
              <sql:param value="${ver.rows[0].estudiante_id}" />
              <sql:param value="${patronEquipo}" />
              <sql:param value="${patronEquipo}" />
              <sql:param value="${patronEquipo}" />
            </sql:query>
          </c:catch>
          <c:if test="${not empty dbError7}">
            <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
          </c:if>
          <c:if test="${empty dbError7 and empty candidatos.rows}">
            <p class="text-muted">No se encontraron estudiantes disponibles.</p>
          </c:if>
          <c:if test="${empty dbError7 and not empty candidatos.rows}">
            <c:if test="${candidatos.rowCount > 10}">
              <div class="alert alert-warning py-2" role="alert">Refina tu búsqueda.</div>
            </c:if>
            <div class="table-responsive">
              <table class="table table-hover align-middle">
                <thead>
                  <tr>
                    <th>Nombre</th>
                    <th>Código</th>
                    <th>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  <c:forEach var="c" items="${candidatos.rows}" varStatus="st">
                    <c:if test="${st.index < 10}">
                      <tr>
                        <td><c:out value="${c.nombre}" /></td>
                        <td><c:out value="${c.codigo}" default="&#8212;" /></td>
                        <td>
                          <form method="post" action="entrega.jsp" class="d-inline">
                            <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
                            <input type="hidden" name="fase" value="1" />
                            <input type="hidden" name="tab" value="equipo" />
                            <input type="hidden" name="estudiante_id" value="${c.id}" />
                            <input type="hidden" name="accion" value="companero" />
                            <button type="submit" class="btn btn-sm btn-lima">Agregar</button>
                          </form>
                        </td>
                      </tr>
                    </c:if>
                  </c:forEach>
                </tbody>
              </table>
            </div>
          </c:if>
        </c:if>
      </c:if>

      <c:if test="${gestionaEquipo and not empty ver.rows[0].estudiante2_id}">
        <button type="button" class="btn btn-warning" data-bs-toggle="modal" data-bs-target="#modalQuitarCompanero">
          <i class="fa-solid fa-user-minus"></i> Quitar compañero(a)
        </button>
        <div class="modal fade" id="modalQuitarCompanero" tabindex="-1" aria-hidden="true">
          <div class="modal-dialog">
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title">Confirmar</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
              </div>
              <div class="modal-body">
                ¿Quitar a <strong><c:out value="${ver.rows[0].est2_nombre}" /></strong> del equipo? ¿Continuar?
              </div>
              <div class="modal-footer">
                <form method="post" action="entrega.jsp">
                  <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
                  <input type="hidden" name="fase" value="1" />
                  <input type="hidden" name="tab" value="equipo" />
                  <input type="hidden" name="accion" value="quitar-companero" />
                  <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                  <button type="submit" class="btn btn-warning">Confirmar</button>
                </form>
              </div>
            </div>
          </div>
        </div>
      </c:if>
    </c:if>

    <c:if test="${param.fase == '1' and esEnviable}">
      <h5 class="mt-3">Requisitos para enviar</h5>
      <ul class="list-unstyled">
        <li>
          <c:if test="${not empty numEntregas and numEntregas > 0}"><i class="fa-solid fa-check text-success"></i></c:if>
          <c:if test="${empty numEntregas or numEntregas == 0}"><i class="fa-solid fa-xmark text-danger"></i></c:if>
          Enlace de pago registrado<c:if test="${not empty uploaderNombre}"> &mdash; Subido por <c:out value="${uploaderNombre}" /></c:if>
        </li>
        <li>
          <c:if test="${ideaValida}"><i class="fa-solid fa-check text-success"></i></c:if>
          <c:if test="${not ideaValida}"><i class="fa-solid fa-xmark text-danger"></i></c:if>
          Idea seleccionada o postulada
        </li>
      </ul>
    </c:if>

    <c:if test="${(param.fase == '1' and cumpleEnvio) or (param.fase != '1' and puedeEnviarFase)}">
      <div class="mt-3">
        <button type="button" class="btn btn-lima" data-bs-toggle="modal" data-bs-target="#modalEnviar">
          <i class="fa-solid fa-paper-plane"></i> <c:out value="${textoEnviar}" />
        </button>
      </div>
      <div class="modal fade" id="modalEnviar" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">Confirmar env&iacute;o</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
            </div>
            <div class="modal-body">
              Una vez enviado no podr&aacute;s registrar m&aacute;s enlaces en esta fase. &iquest;Continuar?
            </div>
            <div class="modal-footer">
              <form method="post" action="fase-enviar.jsp">
                <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
                <input type="hidden" name="fase" value="${fn:escapeXml(param.fase)}" />
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                <button type="submit" class="btn btn-lima">Confirmar</button>
              </form>
            </div>
          </div>
        </div>
      </div>
    </c:if>
    <c:if test="${param.fase == '1' and esEnviable and not cumpleEnvio}">
      <div class="alert alert-warning py-2 mt-3" role="alert">Para enviar falta: <c:if test="${empty numEntregas or numEntregas == 0}">enlace de pago</c:if><c:if test="${(empty numEntregas or numEntregas == 0) and not ideaValida}"> e </c:if><c:if test="${not ideaValida}">idea seleccionada</c:if></div>
    </c:if>
    <c:if test="${param.fase != '1' and esEnviable and empty dbError3 and numEntregas == 0}">
      <div class="alert alert-warning py-2 mt-3" role="alert">Registra al menos un enlace para poder enviar</div>
    </c:if>
  </div>
</div>

<c:import url="includes/footer.jsp" />
