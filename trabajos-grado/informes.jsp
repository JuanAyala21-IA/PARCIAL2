<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  informes.jsp (solo COORDINACION y ADMINISTRADOR)
  Resumen por turno (GROUP BY estado) y tres pestañas (?tipo=):
  alumnos (incluye estudiantes sin proyecto), directores y evaluadores,
  cada una con buscador y paginación propios.
--%>
<c:set var="titulo" value="Informes de proyectos" scope="request" />
<c:set var="activo" value="informes" scope="request" />
<c:set var="rolesPermitidos" value="COORDINACION,ADMINISTRADOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:set var="tipo" value="alumnos" />
<c:if test="${param.tipo == 'directores' or param.tipo == 'evaluadores'}">
  <c:set var="tipo" value="${param.tipo}" />
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

<%-- Resumen: total y cantidad por turno en una sola consulta --%>
<c:catch var="dbError">
  <sql:query var="resumen" dataSource="${db}">
    SELECT estado, COUNT(*) AS n FROM anteproyectos GROUP BY estado
  </sql:query>
</c:catch>
<c:set var="tEst" value="0" />
<c:set var="tDir" value="0" />
<c:set var="tEva" value="0" />
<c:set var="tCoo" value="0" />
<c:forEach var="s" items="${resumen.rows}">
  <c:if test="${s.estado == 'ESTUDIANTE'}"><c:set var="tEst" value="${s.n}" /></c:if>
  <c:if test="${s.estado == 'DIRECTOR'}"><c:set var="tDir" value="${s.n}" /></c:if>
  <c:if test="${s.estado == 'EVALUADOR'}"><c:set var="tEva" value="${s.n}" /></c:if>
  <c:if test="${s.estado == 'COORDINACION'}"><c:set var="tCoo" value="${s.n}" /></c:if>
</c:forEach>
<c:set var="tTotal" value="${tEst + tDir + tEva + tCoo}" />
<c:forEach var="s" items="${resumen.rows}">
  <c:if test="${s.estado != 'ESTUDIANTE' and s.estado != 'DIRECTOR' and s.estado != 'EVALUADOR' and s.estado != 'COORDINACION'}">
    <c:set var="tTotal" value="${tTotal + s.n}" />
  </c:if>
  <c:if test="${s.estado == 'FINALIZADO'}"><c:set var="tFin" value="${s.n}" /></c:if>
</c:forEach>
<c:set var="tFin" value="${empty tFin ? 0 : tFin}" />
<c:catch var="dbErrSus">
  <sql:query var="sus" dataSource="${db}">
    SELECT COUNT(*) AS n FROM anteproyectos WHERE fase = 'FINAL' AND estado = 'COORDINACION'
  </sql:query>
</c:catch>
<c:catch var="dbErrAva">
  <sql:query var="ava" dataSource="${db}">
    SELECT COUNT(*) AS n FROM anteproyectos WHERE estado = 'COORDINACION' AND (fase = '3' OR fase = '5')
  </sql:query>
</c:catch>

<%-- Pestaña Alumnos --%>
<c:if test="${tipo == 'alumnos'}">
  <c:catch var="dbError2">
    <sql:query var="conteo" dataSource="${db}">
      SELECT COUNT(*) AS total FROM usuarios u
      JOIN roles r ON r.id = u.rol_id
      WHERE r.nombre = 'ESTUDIANTE' AND u.estado = 'ACTIVO'
        AND (COALESCE(u.codigo, '') LIKE ? OR u.nombre LIKE ?)
      <sql:param value="${patron}" />
      <sql:param value="${patron}" />
    </sql:query>
  </c:catch>
  <c:set var="total" value="${conteo.rows[0].total}" />
  <fmt:parseNumber var="totalPag" value="${(total + tam - 1) / tam}" integerOnly="true" />
  <c:if test="${totalPag < 1}"><c:set var="totalPag" value="1" /></c:if>
  <c:if test="${pag > totalPag}"><c:set var="pag" value="${totalPag}" /></c:if>
  <c:set var="ini" value="${(pag - 1) * tam}" />
  <c:catch var="dbError3">
    <sql:query var="lista" dataSource="${db}">
      SELECT (SELECT u2.nombre FROM usuarios u2 WHERE u2.id = u.id) AS est,
             (SELECT u2.codigo FROM usuarios u2 WHERE u2.id = u.id) AS est_codigo,
             (SELECT u2.nombre FROM usuarios u2
               WHERE u2.id = CASE WHEN a.estudiante_id = u.id THEN a.estudiante2_id ELSE a.estudiante_id END) AS comp,
             a.id, a.codigo, a.descripcion, a.fase, a.estado,
             a.fecha_sustentacion,
             DATE_FORMAT(a.fecha_sustentacion, '%d/%m/%Y') AS fecha_sus_txt,
             a.nota_sustentacion,
             (SELECT d2.nombre FROM usuarios d2 WHERE d2.id = a.director_id) AS dir,
             (SELECT v2.nombre FROM usuarios v2 WHERE v2.id = a.evaluador_id) AS eva
      FROM usuarios u
      JOIN roles r ON r.id = u.rol_id
      LEFT JOIN anteproyectos a ON a.id = (SELECT MAX(a2.id) FROM anteproyectos a2
                                           WHERE a2.estudiante_id = u.id OR a2.estudiante2_id = u.id)
      WHERE r.nombre = 'ESTUDIANTE' AND u.estado = 'ACTIVO'
        AND (COALESCE(u.codigo, '') LIKE ? OR u.nombre LIKE ?)
      ORDER BY u.nombre LIMIT ? OFFSET ?
      <sql:param value="${patron}" />
      <sql:param value="${patron}" />
      <sql:param value="${tam}" />
      <sql:param value="${ini}" />
    </sql:query>
  </c:catch>
</c:if>

<%-- Pestaña Directores --%>
<c:if test="${tipo == 'directores'}">
  <c:catch var="dbError2">
    <sql:query var="conteo" dataSource="${db}">
      SELECT COUNT(*) AS total FROM usuarios u
      JOIN roles r ON r.id = u.rol_id
      WHERE r.nombre = 'PROFESOR' AND u.estado = 'ACTIVO'
        AND (u.nombre LIKE ? OR u.correo LIKE ?)
      <sql:param value="${patron}" />
      <sql:param value="${patron}" />
    </sql:query>
  </c:catch>
  <c:set var="total" value="${conteo.rows[0].total}" />
  <fmt:parseNumber var="totalPag" value="${(total + tam - 1) / tam}" integerOnly="true" />
  <c:if test="${totalPag < 1}"><c:set var="totalPag" value="1" /></c:if>
  <c:if test="${pag > totalPag}"><c:set var="pag" value="${totalPag}" /></c:if>
  <c:set var="ini" value="${(pag - 1) * tam}" />
  <c:catch var="dbError3">
    <sql:query var="lista" dataSource="${db}">
      SELECT u.id, u.nombre, u.correo,
             COUNT(DISTINCT a.id) AS total,
             COUNT(DISTINCT CASE WHEN a.estado = 'DIRECTOR' THEN a.id END) AS turno,
             (SELECT COUNT(*) FROM revisiones r WHERE r.director_id = u.id AND r.decision = 'APROBADO') AS aprobados,
             (SELECT COUNT(*) FROM revisiones r WHERE r.director_id = u.id AND r.decision = 'DEVUELTO') AS devueltos
      FROM usuarios u
      JOIN roles r ON r.id = u.rol_id
      LEFT JOIN anteproyectos a ON a.director_id = u.id
      WHERE r.nombre = 'PROFESOR' AND u.estado = 'ACTIVO'
        AND (u.nombre LIKE ? OR u.correo LIKE ?)
      GROUP BY u.id, u.nombre, u.correo
      ORDER BY u.nombre LIMIT ? OFFSET ?
      <sql:param value="${patron}" />
      <sql:param value="${patron}" />
      <sql:param value="${tam}" />
      <sql:param value="${ini}" />
    </sql:query>
  </c:catch>
</c:if>

<%-- Pestaña Evaluadores --%>
<c:if test="${tipo == 'evaluadores'}">
  <c:catch var="dbError2">
    <sql:query var="conteo" dataSource="${db}">
      SELECT COUNT(*) AS total FROM usuarios u
      JOIN roles r ON r.id = u.rol_id
      WHERE r.nombre = 'PROFESOR' AND u.estado = 'ACTIVO'
        AND (u.nombre LIKE ? OR u.correo LIKE ?)
      <sql:param value="${patron}" />
      <sql:param value="${patron}" />
    </sql:query>
  </c:catch>
  <c:set var="total" value="${conteo.rows[0].total}" />
  <fmt:parseNumber var="totalPag" value="${(total + tam - 1) / tam}" integerOnly="true" />
  <c:if test="${totalPag < 1}"><c:set var="totalPag" value="1" /></c:if>
  <c:if test="${pag > totalPag}"><c:set var="pag" value="${totalPag}" /></c:if>
  <c:set var="ini" value="${(pag - 1) * tam}" />
  <c:catch var="dbError3">
    <sql:query var="lista" dataSource="${db}">
      SELECT u.id, u.nombre, u.correo,
             COUNT(DISTINCT a.id) AS total,
             COUNT(DISTINCT CASE WHEN a.estado = 'EVALUADOR' THEN a.id END) AS turno,
             (SELECT COUNT(*) FROM evaluaciones e WHERE e.evaluador_id = u.id AND e.decision = 'APROBADO') AS aprobados,
             (SELECT COUNT(*) FROM evaluaciones e WHERE e.evaluador_id = u.id AND e.decision = 'DEVUELTO') AS devueltos
      FROM usuarios u
      JOIN roles r ON r.id = u.rol_id
      LEFT JOIN anteproyectos a ON a.evaluador_id = u.id
      WHERE r.nombre = 'PROFESOR' AND u.estado = 'ACTIVO'
        AND (u.nombre LIKE ? OR u.correo LIKE ?)
      GROUP BY u.id, u.nombre, u.correo
      ORDER BY u.nombre LIMIT ? OFFSET ?
      <sql:param value="${patron}" />
      <sql:param value="${patron}" />
      <sql:param value="${tam}" />
      <sql:param value="${ini}" />
    </sql:query>
  </c:catch>
</c:if>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<c:url var="urlPrimera" value="informes.jsp">
  <c:param name="tipo" value="${tipo}" />
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="1" />
</c:url>
<c:url var="urlAnterior" value="informes.jsp">
  <c:param name="tipo" value="${tipo}" />
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="${pag - 1}" />
</c:url>
<c:url var="urlSiguiente" value="informes.jsp">
  <c:param name="tipo" value="${tipo}" />
  <c:param name="size" value="${tam}" />
  <c:param name="q" value="${param.q}" />
  <c:param name="page" value="${pag + 1}" />
</c:url>
<c:url var="urlUltima" value="informes.jsp">
  <c:param name="tipo" value="${tipo}" />
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="${totalPag}" />
</c:url>

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Informes de <span class="badge-lima">PROYECTOS</span></h4>
    </div>
    <hr />

    <c:if test="${not empty dbError or not empty dbError2 or not empty dbError3}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <div class="resumen-grid mb-3">
      <div class="resumen-card"><span class="resumen-num"><c:out value="${tTotal}" /></span><span class="resumen-txt">Proyectos</span></div>
      <div class="resumen-card"><span class="resumen-num"><c:out value="${tEst}" /></span><span class="resumen-txt">Estudiante</span></div>
      <div class="resumen-card"><span class="resumen-num"><c:out value="${tDir}" /></span><span class="resumen-txt">Director</span></div>
      <div class="resumen-card"><span class="resumen-num"><c:out value="${tEva}" /></span><span class="resumen-txt">Evaluador</span></div>
      <div class="resumen-card"><span class="resumen-num"><c:out value="${tCoo}" /></span><span class="resumen-txt">Coordinaci&oacute;n</span></div>
      <div class="resumen-card"><span class="resumen-num"><c:out value="${ava.rows[0].n}" default="0" /></span><span class="resumen-txt">Avales pendientes</span></div>
      <div class="resumen-card"><span class="resumen-num"><c:out value="${sus.rows[0].n}" default="0" /></span><span class="resumen-txt">En sustentaci&oacute;n</span></div>
      <div class="resumen-card"><span class="resumen-num"><c:out value="${tFin}" /></span><span class="resumen-txt">Finalizados</span></div>
    </div>

    <ul class="nav nav-tabs mb-3">
      <li class="nav-item"><a class="nav-link ${tipo == 'alumnos' ? 'active' : ''}" href="informes.jsp?tipo=alumnos">Alumnos</a></li>
      <li class="nav-item"><a class="nav-link ${tipo == 'directores' ? 'active' : ''}" href="informes.jsp?tipo=directores">Directores</a></li>
      <li class="nav-item"><a class="nav-link ${tipo == 'evaluadores' ? 'active' : ''}" href="informes.jsp?tipo=evaluadores">Evaluadores</a></li>
    </ul>

    <form method="get" action="informes.jsp" class="tabla-toolbar mb-3">
      <input type="hidden" name="tipo" value="${tipo}" />
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

    <c:if test="${tipo == 'alumnos'}">
      <div class="table-responsive">
        <table class="table table-hover align-middle">
          <thead>
            <tr>
              <th>Estudiante</th>
              <th>Compañero(a)</th>
              <th>Proyecto</th>
              <th>Director</th>
              <th>Evaluador</th>
              <th>Fase</th>
              <th>Turno</th>
              <th>Sustentaci&oacute;n</th>
              <th>Nota final</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="a" items="${lista.rows}">
              <tr>
                <td><c:out value="${a.est}" /><br /><small class="text-muted"><c:out value="${a.est_codigo}" /></small></td>
                <td><c:out value="${a.comp}" default="&#8212;" /></td>
                <td>
                  <c:choose>
                    <c:when test="${not empty a.id}">
                      <strong><c:out value="${a.codigo}" /></strong><br />
                      <small class="text-muted"><c:out value="${fn:substring(a.descripcion, 0, 60)}" /><c:if test="${fn:length(a.descripcion) > 60}">...</c:if></small>
                    </c:when>
                    <c:otherwise>
                      <span class="text-muted">Sin proyecto</span>
                    </c:otherwise>
                  </c:choose>
                </td>
                <td>
                  <c:choose>
                    <c:when test="${not empty a.dir}"><c:out value="${a.dir}" /></c:when>
                    <c:otherwise><span class="text-muted">Sin asignar</span></c:otherwise>
                  </c:choose>
                </td>
                <td>
                  <c:choose>
                    <c:when test="${not empty a.eva}"><c:out value="${a.eva}" /></c:when>
                    <c:otherwise><span class="text-muted">Sin asignar</span></c:otherwise>
                  </c:choose>
                </td>
                <td>
                  <c:if test="${not empty a.id}">
                    <span class="badge-fase text-nowrap">Fase <c:out value="${a.fase}" /></span>
                  </c:if>
                  <c:if test="${empty a.id}">
                    <span class="text-muted">&#8212;</span>
                  </c:if>
                </td>
                <td>
                  <c:if test="${not empty a.id}">
                    <c:if test="${a.estado == 'FINALIZADO'}">
                      <span class="badge text-bg-success text-nowrap">Finalizado</span>
                    </c:if>
                    <c:if test="${a.estado != 'FINALIZADO'}">
                      <span class="badge-turno text-nowrap"><c:out value="${a.estado}" /></span>
                    </c:if>
                  </c:if>
                  <c:if test="${empty a.id}">
                    <span class="text-muted">&#8212;</span>
                  </c:if>
                </td>
                <td>
                  <c:out value="${a.fecha_sus_txt}" default="&#8212;" />
                </td>
                <td>
                  <c:out value="${a.nota_sustentacion}" default="&#8212;" />
                </td>
                <td>
                  <c:if test="${not empty a.id}">
                    <c:url var="urlVer" value="proyecto-ver.jsp">
                      <c:param name="id" value="${a.id}" />
                    </c:url>
                    <a href="${urlVer}" class="btn btn-sm btn-dark" title="Ver"><i class="fa-solid fa-eye"></i></a>
                  </c:if>
                </td>
              </tr>
            </c:forEach>
            <c:if test="${empty lista.rows}">
              <tr><td colspan="10" class="text-center text-muted">Sin resultados.</td></tr>
            </c:if>
          </tbody>
        </table>
      </div>
    </c:if>

    <c:if test="${tipo == 'directores' or tipo == 'evaluadores'}">
      <div class="table-responsive">
        <table class="table table-hover align-middle">
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Correo</th>
              <th>A cargo</th>
              <th>En turno</th>
              <th>Aprobados</th>
              <th>Devueltos</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="d" items="${lista.rows}">
              <tr>
                <td>
                  <button class="btn btn-link p-0 text-start" type="button" data-bs-toggle="collapse" data-bs-target="#col${tipo}${d.id}" aria-expanded="false">
                    <c:out value="${d.nombre}" />
                  </button>
                </td>
                <td><c:out value="${d.correo}" /></td>
                <td><c:out value="${d.total}" /></td>
                <td><c:out value="${d.turno}" /></td>
                <td><c:out value="${d.aprobados}" /></td>
                <td><c:out value="${d.devueltos}" /></td>
              </tr>
              <tr class="collapse" id="col${tipo}${d.id}">
                <td colspan="6">
                  <c:catch var="dbError4">
                    <sql:query var="detalle" dataSource="${db}">
                      SELECT a.id, a.codigo, a.fase, a.estado,
                             (SELECT e2.nombre FROM usuarios e2 WHERE e2.id = a.estudiante_id) AS estudiante
                      FROM anteproyectos a
                      WHERE a.director_id = ?
                      ORDER BY a.id DESC
                      <sql:param value="${d.id}" />
                    </sql:query>
                  </c:catch>
                  <c:if test="${tipo == 'evaluadores'}">
                    <c:catch var="dbError4">
                      <sql:query var="detalle" dataSource="${db}">
                        SELECT a.id, a.codigo, a.fase, a.estado,
                               (SELECT e2.nombre FROM usuarios e2 WHERE e2.id = a.estudiante_id) AS estudiante
                        FROM anteproyectos a
                        WHERE a.evaluador_id = ?
                        ORDER BY a.id DESC
                        <sql:param value="${d.id}" />
                      </sql:query>
                    </c:catch>
                  </c:if>
                  <c:if test="${empty detalle.rows}">
                    <small class="text-muted">Sin proyectos a cargo.</small>
                  </c:if>
                  <c:forEach var="g" items="${detalle.rows}">
                    <p class="mb-1">
                      <strong><c:out value="${g.codigo}" /></strong> &middot;
                      <c:out value="${g.estudiante}" default="Sin estudiante" /> &middot;
                      <span class="badge-fase">Fase <c:out value="${g.fase}" /></span>
                      <c:if test="${g.estado == 'FINALIZADO'}">
                        <span class="badge text-bg-success">Finalizado</span>
                      </c:if>
                      <c:if test="${g.estado != 'FINALIZADO'}">
                        <span class="badge-turno"><c:out value="${g.estado}" /></span>
                      </c:if>
                    </p>
                  </c:forEach>
                </td>
              </tr>
            </c:forEach>
            <c:if test="${empty lista.rows}">
              <tr><td colspan="6" class="text-center text-muted">Sin resultados.</td></tr>
            </c:if>
          </tbody>
        </table>
      </div>
    </c:if>

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
