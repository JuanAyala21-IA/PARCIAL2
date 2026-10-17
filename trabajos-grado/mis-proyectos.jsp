<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  mis-proyectos.jsp (todos los roles autenticados)
  Alcance por rol con <c:choose> dentro de la consulta:
  ESTUDIANTE (estudiante_id o estudiante2_id), DIRECTOR (director_id),
  EVALUADOR (evaluador_id), COORDINACION y ADMINISTRADOR (todos).
  Busqueda por codigo GRA, descripcion, nombre o codigo del estudiante
  (o de su companero de equipo).
  El boton morado lleva a seguimiento.jsp (se crea en la siguiente tarea).
--%>
<c:set var="titulo" value="Mis proyectos" scope="request" />
<c:set var="activo" value="proyectos" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:set var="puedeAsignar" value="${sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR'}" scope="request" />

<%-- Proyecto activo del estudiante (para "Iniciar proyecto de grado") --%>
<c:if test="${sessionScope.rol == 'ESTUDIANTE'}">
  <c:catch var="dbError0">
    <sql:query var="miProyecto" dataSource="${db}">
      SELECT id FROM anteproyectos
      WHERE (estudiante_id = ? OR estudiante2_id = ?) AND estado <> 'RECHAZADO'
      <sql:param value="${sessionScope.usuarioId}" />
      <sql:param value="${sessionScope.usuarioId}" />
    </sql:query>
  </c:catch>
  <c:set var="tieneProyecto" value="${not empty miProyecto and miProyecto.rowCount > 0}" scope="request" />
</c:if>

<%-- Normalizar parametros GET --%>
<c:set var="tam" value="${5}" />
<c:if test="${param.size == 5 or param.size == 10 or param.size == 25}">
  <c:set var="tam" value="${param.size * 1}" />
</c:if>
<c:set var="pag" value="${1}" />
<c:if test="${param.page > 1}">
  <c:set var="pag" value="${param.page * 1}" />
</c:if>
<c:set var="patron" value="%${param.q}%" />

<%-- Total de registros con el mismo filtro y alcance --%>
<c:catch var="dbError">
  <sql:query var="conteo" dataSource="${db}">
    SELECT COUNT(*) AS total
    FROM anteproyectos a
    LEFT JOIN usuarios e ON e.id = a.estudiante_id
    LEFT JOIN usuarios e2 ON e2.id = a.estudiante2_id
    WHERE (a.codigo LIKE ? OR a.descripcion LIKE ? OR e.nombre LIKE ? OR COALESCE(e.codigo, '') LIKE ?
           OR e2.nombre LIKE ? OR COALESCE(e2.codigo, '') LIKE ?)
    <c:choose>
      <c:when test="${sessionScope.rol == 'ESTUDIANTE'}">AND (a.estudiante_id = ? OR a.estudiante2_id = ?)</c:when>
      <c:when test="${sessionScope.rol == 'PROFESOR'}">AND (a.director_id = ? OR a.evaluador_id = ?)</c:when>
    </c:choose>
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <c:if test="${sessionScope.rol == 'ESTUDIANTE'}">
      <sql:param value="${sessionScope.usuarioId}" />
      <sql:param value="${sessionScope.usuarioId}" />
    </c:if>
    <c:if test="${sessionScope.rol == 'PROFESOR'}">
      <sql:param value="${sessionScope.usuarioId}" />
      <sql:param value="${sessionScope.usuarioId}" />
    </c:if>
    <c:if test="${(sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR') and param.pendientes == 1}">AND a.fase = '1' AND a.estado = 'COORDINACION'</c:if>
    <c:if test="${(sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR') and param.avales == 1}">AND a.estado = 'COORDINACION' AND (a.fase = '3' OR a.fase = '5')</c:if>
  </sql:query>
</c:catch>
<c:set var="total" value="${conteo.rows[0].total}" />
<fmt:parseNumber var="totalPag" value="${(total + tam - 1) / tam}" integerOnly="true" />
<c:if test="${totalPag < 1}">
  <c:set var="totalPag" value="1" />
</c:if>
<c:if test="${pag > totalPag}">
  <c:set var="pag" value="${totalPag}" />
</c:if>
<c:set var="ini" value="${(pag - 1) * tam}" />

<%-- Pagina actual --%>
<c:catch var="dbError2">
  <sql:query var="lista" dataSource="${db}">
    SELECT a.id, a.codigo, a.descripcion, a.fase, a.estado, a.director_id, a.evaluador_id,
           a.estudiante_id, a.estudiante2_id,
           (SELECT u5.nombre FROM usuarios u5 WHERE u5.id = a.estudiante_id) AS est_nombre,
           (SELECT u6.nombre FROM usuarios u6 WHERE u6.id = a.estudiante2_id) AS comp_nombre,
           CASE WHEN a.director_id = ? THEN 'Director' WHEN a.evaluador_id = ? THEN 'Evaluador' ELSE '' END AS mi_rol
    FROM anteproyectos a
    LEFT JOIN usuarios e ON e.id = a.estudiante_id
    LEFT JOIN usuarios e2 ON e2.id = a.estudiante2_id
    WHERE (a.codigo LIKE ? OR a.descripcion LIKE ? OR e.nombre LIKE ? OR COALESCE(e.codigo, '') LIKE ?
           OR e2.nombre LIKE ? OR COALESCE(e2.codigo, '') LIKE ?)
    <c:choose>
      <c:when test="${sessionScope.rol == 'ESTUDIANTE'}">AND (a.estudiante_id = ? OR a.estudiante2_id = ?)</c:when>
      <c:when test="${sessionScope.rol == 'PROFESOR'}">AND (a.director_id = ? OR a.evaluador_id = ?)</c:when>
    </c:choose>
    <c:if test="${(sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR') and param.pendientes == 1}">AND a.fase = '1' AND a.estado = 'COORDINACION'</c:if>
    <c:if test="${(sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR') and param.avales == 1}">AND a.estado = 'COORDINACION' AND (a.fase = '3' OR a.fase = '5')</c:if>
    ORDER BY a.id DESC LIMIT ? OFFSET ?
    <sql:param value="${sessionScope.usuarioId}" />
    <sql:param value="${sessionScope.usuarioId}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <c:if test="${sessionScope.rol == 'ESTUDIANTE'}">
      <sql:param value="${sessionScope.usuarioId}" />
      <sql:param value="${sessionScope.usuarioId}" />
    </c:if>
    <c:if test="${sessionScope.rol == 'PROFESOR'}">
      <sql:param value="${sessionScope.usuarioId}" />
      <sql:param value="${sessionScope.usuarioId}" />
    </c:if>
    <sql:param value="${tam}" />
    <sql:param value="${ini}" />
  </sql:query>
</c:catch>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<c:url var="urlPrimera" value="mis-proyectos.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="pendientes" value="${param.pendientes}" />
  <c:param name="avales" value="${param.avales}" />
  <c:param name="page" value="1" />
</c:url>
<c:url var="urlAnterior" value="mis-proyectos.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="pendientes" value="${param.pendientes}" />
  <c:param name="avales" value="${param.avales}" />
  <c:param name="page" value="${pag - 1}" />
</c:url>
<c:url var="urlSiguiente" value="mis-proyectos.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="pendientes" value="${param.pendientes}" />
  <c:param name="avales" value="${param.avales}" />
  <c:param name="page" value="${pag + 1}" />
</c:url>
<c:url var="urlUltima" value="mis-proyectos.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="pendientes" value="${param.pendientes}" />
  <c:param name="avales" value="${param.avales}" />
  <c:param name="page" value="${totalPag}" />
</c:url>

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Proyectos de <span class="badge-lima">GRADO</span></h4>
      <div class="d-flex gap-2">
        <c:if test="${sessionScope.rol == 'ESTUDIANTE' and not tieneProyecto}">
          <button type="button" class="btn btn-lima" data-bs-toggle="modal" data-bs-target="#modalIniciar"><i class="fa-solid fa-plus"></i> Iniciar proyecto de grado</button>
        </c:if>
        <a href="#" class="btn btn-danger" title="Avisos"><i class="fa-solid fa-triangle-exclamation"></i></a>
      </div>
    </div>
    <hr />

    <div class="modal fade" id="modalIniciar" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Iniciar proyecto de grado</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
          </div>
          <div class="modal-body">
            &iquest;Iniciar tu proyecto de grado? Podr&aacute;s registrar el enlace de pago y elegir una idea del banco en la Fase 1.
          </div>
          <div class="modal-footer">
            <form method="post" action="iniciar-proyecto.jsp">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
              <button type="submit" class="btn btn-lima">Confirmar</button>
            </form>
          </div>
        </div>
      </div>
    </div>

    <c:if test="${not empty dbError or not empty dbError2}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>
    <c:if test="${param.ok == 5}">
      <div class="alert alert-success py-2" role="alert">Solicitud aprobada: idea, director y evaluador asignados. El proyecto pas&oacute; a la Fase 2.</div>
    </c:if>
    <c:if test="${param.ok == 6}">
      <div class="alert alert-success py-2" role="alert">Revisi&oacute;n registrada y proyecto enviado al Evaluador.</div>
    </c:if>
    <c:if test="${param.ok == 7}">
      <div class="alert alert-success py-2" role="alert">Proyecto devuelto al estudiante.</div>
    </c:if>
    <c:if test="${param.ok == 11}">
      <div class="alert alert-success py-2" role="alert">Solicitud devuelta al estudiante.</div>
    </c:if>
    <c:if test="${param.ok == 12}">
      <div class="alert alert-success py-2" role="alert">Proyecto finalizado.</div>
    </c:if>
    <c:if test="${param.ok == 9}">
      <div class="alert alert-success py-2" role="alert">Aprobación enviada a Coordinación para su aval.</div>
    </c:if>
    <c:if test="${param.ok == 10}">
      <div class="alert alert-success py-2" role="alert">Proyecto devuelto al estudiante.</div>
    </c:if>
    <c:if test="${param.ok == 13}">
      <div class="alert alert-success py-2" role="alert">Aprobación avalada: el proyecto continúa su flujo.</div>
    </c:if>
    <c:if test="${param.ok == 14}">
      <div class="alert alert-success py-2" role="alert">No avalado: el proyecto volvió al evaluador.</div>
    </c:if>
    <c:if test="${param.error == 'idea-no-disponible'}">
      <div class="alert alert-danger py-2" role="alert">La idea solicitada ya no est&aacute; disponible.</div>
    </c:if>
    <c:if test="${param.error == 'no-aplica'}">
      <div class="alert alert-danger py-2" role="alert">El proyecto no est&aacute; disponible para esta acci&oacute;n.</div>
    </c:if>

    <form method="get" action="mis-proyectos.jsp" class="tabla-toolbar mb-3">
      <div class="d-flex align-items-center gap-2">
        <label for="size" class="text-nowrap">Mostrar</label>
        <select id="size" name="size" class="form-select form-select-sm w-auto" onchange="this.form.submit()">
          <option value="5" ${tam == 5 ? 'selected' : ''}>5</option>
          <option value="10" ${tam == 10 ? 'selected' : ''}>10</option>
          <option value="25" ${tam == 25 ? 'selected' : ''}>25</option>
        </select>
        <span class="text-nowrap">registros por p&aacute;gina</span>
      </div>
      <div class="d-flex align-items-center gap-2">
        <label for="q" class="text-nowrap">Buscar:</label>
        <input type="search" id="q" name="q" class="form-control form-control-sm"
               placeholder="Ingrese una clave." value="${fn:escapeXml(param.q)}" />
        <button type="submit" class="btn btn-sm btn-lima text-nowrap">Buscar</button>
      </div>
    </form>

    <div class="table-responsive">
      <table class="table table-hover align-middle">
        <thead>
          <tr>
            <th>ID</th>
            <th>Descripci&oacute;n</th>
            <th>Estado</th>
            <c:if test="${sessionScope.rol == 'PROFESOR'}">
              <th>Mi rol</th>
            </c:if>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <c:forEach var="p" items="${lista.rows}">
            <c:set var="turno" value="" />
            <c:if test="${p.estado == 'ESTUDIANTE'}"><c:set var="turno" value="Estudiante" /></c:if>
            <c:if test="${p.estado == 'DIRECTOR'}"><c:set var="turno" value="Director" /></c:if>
            <c:if test="${p.estado == 'EVALUADOR'}"><c:set var="turno" value="Evaluador" /></c:if>
            <c:if test="${p.estado == 'COORDINACION' and (p.fase == '3' or p.fase == '5')}"><c:set var="turno" value="Coordinación (aval)" /></c:if>
            <c:if test="${p.estado == 'COORDINACION' and p.fase != '3' and p.fase != '5'}"><c:set var="turno" value="Coordinación" /></c:if>
            <tr>
              <td class="text-nowrap"><c:out value="${p.codigo}" /></td>
              <td>
                <c:out value="${fn:substring(p.descripcion, 0, 80)}" /><c:if test="${fn:length(p.descripcion) > 80}">...</c:if>
                <c:if test="${sessionScope.rol == 'ESTUDIANTE' and not empty p.estudiante2_id}">
                  <br /><small class="text-muted">Equipo con: <c:out value="${p.estudiante_id == sessionScope.usuarioId ? p.comp_nombre : p.est_nombre}" /></small>
                </c:if>
              </td>
              <td>
                <span class="badge-fase text-nowrap">Fase <c:out value="${p.fase}" /></span>
                <c:if test="${p.estado == 'FINALIZADO'}">
                  <span class="badge text-bg-success text-nowrap">Finalizado</span>
                </c:if>
                <c:if test="${p.estado != 'FINALIZADO'}">
                  <span class="badge-turno text-nowrap"><c:out value="${p.estado}" /><c:if test="${not empty turno}"> &middot; <c:out value="${turno}" /></c:if></span>
                </c:if>
              </td>
              <c:if test="${sessionScope.rol == 'PROFESOR'}">
                <td>
                  <c:if test="${p.mi_rol == 'Director'}">
                    <span class="badge-lima text-nowrap">Director</span>
                  </c:if>
                  <c:if test="${p.mi_rol == 'Evaluador'}">
                    <span class="badge text-bg-dark text-nowrap">Evaluador</span>
                  </c:if>
                </td>
              </c:if>
              <td class="text-nowrap">
                <c:url var="urlVer" value="proyecto-ver.jsp">
                  <c:param name="id" value="${p.id}" />
                </c:url>
                <c:url var="urlSeg" value="seguimiento.jsp">
                  <c:param name="id" value="${p.id}" />
                </c:url>
                <a href="${urlVer}" class="btn btn-sm btn-dark" title="Ver"><i class="fa-solid fa-eye"></i></a>
                <a href="${urlSeg}" class="btn btn-sm btn-morado" title="Seguimiento"><i class="fa-solid fa-map"></i></a>
                <c:if test="${(sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR') and p.fase == 'FINAL'}">
                  <c:url var="urlSus" value="sustentacion.jsp">
                    <c:param name="id" value="${p.id}" />
                  </c:url>
                  <a href="${urlSus}" class="btn btn-sm btn-lima" title="Sustentación"><i class="fa-solid fa-graduation-cap"></i></a>
                </c:if>
                <c:if test="${(sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR') and p.fase == '1' and p.estado == 'COORDINACION'}">
                  <c:url var="urlAte" value="atender-solicitud.jsp">
                    <c:param name="id" value="${p.id}" />
                  </c:url>
                  <a href="${urlAte}" class="btn btn-sm btn-lima" title="Atender solicitud"><i class="fa-solid fa-inbox"></i></a>
                </c:if>
                <c:if test="${(sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR') and (p.fase == '3' or p.fase == '5') and p.estado == 'COORDINACION'}">
                  <c:url var="urlAva" value="avalar.jsp">
                    <c:param name="id" value="${p.id}" />
                  </c:url>
                  <a href="${urlAva}" class="btn btn-sm btn-lima" title="Avalar decisión del evaluador"><i class="fa-solid fa-file-signature"></i></a>
                </c:if>
                <c:if test="${sessionScope.rol == 'PROFESOR' and p.director_id == sessionScope.usuarioId and p.estado == 'DIRECTOR' and (p.fase == '2' or p.fase == '4')}">
                  <c:url var="urlRev" value="revisar.jsp">
                    <c:param name="id" value="${p.id}" />
                  </c:url>
                  <a href="${urlRev}" class="btn btn-sm btn-lima" title="Revisar"><i class="fa-solid fa-check-double"></i></a>
                </c:if>
                <c:if test="${sessionScope.rol == 'PROFESOR' and p.evaluador_id == sessionScope.usuarioId and p.estado == 'EVALUADOR' and (p.fase == '3' or p.fase == '5')}">
                  <c:url var="urlEv" value="evaluar.jsp">
                    <c:param name="id" value="${p.id}" />
                  </c:url>
                  <a href="${urlEv}" class="btn btn-sm btn-lima" title="Evaluar"><i class="fa-solid fa-clipboard-check"></i></a>
                </c:if>
              </td>
            </tr>
          </c:forEach>
          <c:if test="${empty lista.rows}">
            <c:choose>
              <c:when test="${sessionScope.rol == 'ESTUDIANTE' and not tieneProyecto}">
                <tr><td colspan="4" class="text-center text-muted">A&uacute;n no has iniciado tu proyecto.</td></tr>
              </c:when>
              <c:otherwise>
                <tr><td colspan="4" class="text-center text-muted">Sin resultados.</td></tr>
              </c:otherwise>
            </c:choose>
          </c:if>
        </tbody>
      </table>
    </div>

    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <small class="text-muted">Mostrando la p&aacute;gina ${pag} de ${totalPag} (${total} registros)</small>
      <nav aria-label="Paginaci&oacute;n">
        <ul class="pagination pagination-sm mb-0">
          <li class="page-item ${pag == 1 ? 'disabled' : ''}"><a class="page-link" href="${urlPrimera}">&laquo;</a></li>
          <li class="page-item ${pag == 1 ? 'disabled' : ''}"><a class="page-link" href="${urlAnterior}">&lsaquo;</a></li>
          <li class="page-item active"><span class="page-link">${pag}</span></li>
          <li class="page-item ${pag == totalPag ? 'disabled' : ''}"><a class="page-link" href="${urlSiguiente}">&rsaquo;</a></li>
          <li class="page-item ${pag == totalPag ? 'disabled' : ''}"><a class="page-link" href="${urlUltima}">&raquo;</a></li>
        </ul>
      </nav>
    </div>
  </div>
</div>

<c:import url="includes/footer.jsp" />
