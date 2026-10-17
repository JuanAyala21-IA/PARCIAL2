<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  ideas.jsp (banco de ideas, todos los roles autenticados)
  Crear/editar/eliminar solo COORDINACION.
  Busqueda por titulo/descripcion, tamano de pagina y paginacion por GET.
--%>
<c:set var="titulo" value="Banco de ideas" scope="request" />
<c:set var="activo" value="ideas" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:set var="puedeGestionar" value="${sessionScope.rol == 'COORDINACION'}" scope="request" />

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

<%-- Total de registros con el mismo filtro --%>
<c:catch var="dbError">
  <sql:query var="conteo" dataSource="${db}">
    SELECT COUNT(*) AS total FROM ideas i
    WHERE (i.titulo LIKE ? OR i.descripcion LIKE ?) AND i.estado <> 'POSTULADA'
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
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
    SELECT i.id, i.titulo, i.descripcion, i.estado,
           (SELECT u2.nombre FROM usuarios u2 WHERE u2.id = i.propuesta_por) AS propuesta
    FROM ideas i
    WHERE (i.titulo LIKE ? OR i.descripcion LIKE ?) AND i.estado <> 'POSTULADA'
    ORDER BY i.id DESC LIMIT ? OFFSET ?
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${tam}" />
    <sql:param value="${ini}" />
  </sql:query>
</c:catch>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<c:url var="urlPrimera" value="ideas.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="1" />
</c:url>
<c:url var="urlAnterior" value="ideas.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="${pag - 1}" />
</c:url>
<c:url var="urlSiguiente" value="ideas.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="${pag + 1}" />
</c:url>
<c:url var="urlUltima" value="ideas.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="${totalPag}" />
</c:url>

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Banco de <span class="badge-lima">IDEAS</span></h4>
      <c:if test="${puedeGestionar}">
        <a href="idea-form.jsp" class="btn btn-lima"><i class="fa-solid fa-plus"></i> Nueva idea</a>
      </c:if>
    </div>
    <hr />

    <c:if test="${sessionScope.rol == 'ESTUDIANTE'}">
      <div class="alert alert-info py-2" role="alert">Las ideas se eligen desde tu proyecto, en la Fase 1 (<a href="mis-proyectos.jsp" class="alert-link">Mis proyectos</a>).</div>
    </c:if>

    <c:if test="${param.ok == 1}">
      <div class="alert alert-success py-2" role="alert">Idea registrada.</div>
    </c:if>
    <c:if test="${param.ok == 2}">
      <div class="alert alert-success py-2" role="alert">Idea actualizada.</div>
    </c:if>
    <c:if test="${param.ok == 3}">
      <div class="alert alert-success py-2" role="alert">Idea eliminada.</div>
    </c:if>
    <c:if test="${param.error == 'asignada'}">
      <div class="alert alert-danger py-2" role="alert">La idea est&aacute; ASIGNADA o tiene un anteproyecto asociado y no puede eliminarse.</div>
    </c:if>
    <c:if test="${param.error == 'solicitada'}">
      <div class="alert alert-danger py-2" role="alert">La idea est&aacute; solicitada por un proyecto.</div>
    </c:if>
    <c:if test="${param.error == 'postulada'}">
      <div class="alert alert-danger py-2" role="alert">Esta idea fue propuesta por un estudiante; no se puede editar ni eliminar desde el banco.</div>
    </c:if>
    <c:if test="${not empty dbError or not empty dbError2}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <form method="get" action="ideas.jsp" class="tabla-toolbar mb-3">
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
            <th>T&iacute;tulo</th>
            <th>Descripci&oacute;n</th>
            <th>Estado</th>
            <th>Propuesta por</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <c:forEach var="i" items="${lista.rows}">
            <tr>
              <td><c:out value="${i.titulo}" /></td>
              <td>
                <c:out value="${fn:substring(i.descripcion, 0, 80)}" /><c:if test="${fn:length(i.descripcion) > 80}">...</c:if>
              </td>
              <td>
                <c:if test="${i.estado == 'DISPONIBLE'}">
                  <span class="badge text-bg-success">DISPONIBLE</span>
                </c:if>
                <c:if test="${i.estado != 'DISPONIBLE'}">
                  <span class="badge text-bg-secondary"><c:out value="${i.estado}" /></span>
                </c:if>
              </td>
              <td><c:out value="${i.propuesta}" default="&#8212;" /></td>
              <td class="text-nowrap">
                <c:url var="urlVer" value="idea-ver.jsp">
                  <c:param name="id" value="${i.id}" />
                </c:url>
                <a href="${urlVer}" class="btn btn-sm btn-dark" title="Ver"><i class="fa-solid fa-eye"></i></a>
                <c:if test="${puedeGestionar}">
                  <c:url var="urlEditar" value="idea-form.jsp">
                    <c:param name="id" value="${i.id}" />
                  </c:url>
                  <a href="${urlEditar}" class="btn btn-sm btn-lima" title="Editar"><i class="fa-solid fa-pen"></i></a>
                  <button type="button" class="btn btn-sm btn-danger" title="Eliminar"
                          data-bs-toggle="modal" data-bs-target="#modalEliminar${i.id}"><i class="fa-solid fa-trash"></i></button>
                </c:if>
              </td>
            </tr>
            <c:if test="${puedeGestionar}">
              <div class="modal fade" id="modalEliminar${i.id}" tabindex="-1" aria-hidden="true">
                <div class="modal-dialog">
                  <div class="modal-content">
                    <div class="modal-header">
                      <h5 class="modal-title">Confirmar eliminaci&oacute;n</h5>
                      <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                    </div>
                    <div class="modal-body">
                      &iquest;Eliminar la idea <strong><c:out value="${i.titulo}" /></strong>?
                    </div>
                    <div class="modal-footer">
                      <form method="post" action="idea-eliminar.jsp">
                        <input type="hidden" name="id" value="${i.id}" />
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                        <button type="submit" class="btn btn-danger">Eliminar</button>
                      </form>
                    </div>
                  </div>
                </div>
              </div>
            </c:if>
          </c:forEach>
          <c:if test="${empty lista.rows}">
            <tr><td colspan="5" class="text-center text-muted">Sin resultados.</td></tr>
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
