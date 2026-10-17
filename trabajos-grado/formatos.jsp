<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  formatos.jsp (todos los roles autenticados, "Base documental")
  Busqueda por nombre/descripcion, tamano de pagina y paginacion por GET.
  Crear/editar/eliminar solo COORDINACION y ADMINISTRADOR.
--%>
<c:set var="titulo" value="Base documental" scope="request" />
<c:set var="activo" value="documental" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:set var="puedeGestionar" value="${sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR'}" scope="request" />

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
    SELECT COUNT(*) AS total FROM formatos f
    WHERE (f.nombre LIKE ? OR COALESCE(f.descripcion, '') LIKE ?)
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
    SELECT id, nombre, descripcion, categoria, enlace
    FROM formatos
    WHERE (nombre LIKE ? OR COALESCE(descripcion, '') LIKE ?)
    ORDER BY id DESC LIMIT ? OFFSET ?
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${tam}" />
    <sql:param value="${ini}" />
  </sql:query>
</c:catch>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<c:url var="urlPrimera" value="formatos.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="1" />
</c:url>
<c:url var="urlAnterior" value="formatos.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="${pag - 1}" />
</c:url>
<c:url var="urlSiguiente" value="formatos.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="${pag + 1}" />
</c:url>
<c:url var="urlUltima" value="formatos.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="${totalPag}" />
</c:url>

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Base <span class="badge-lima">DOCUMENTAL</span></h4>
      <c:if test="${puedeGestionar}">
        <a href="formato-form.jsp" class="btn btn-lima"><i class="fa-solid fa-plus"></i> Nuevo formato</a>
      </c:if>
    </div>
    <hr />

    <c:if test="${param.ok == 1}">
      <div class="alert alert-success py-2" role="alert">Formato registrado.</div>
    </c:if>
    <c:if test="${param.ok == 2}">
      <div class="alert alert-success py-2" role="alert">Formato actualizado.</div>
    </c:if>
    <c:if test="${param.ok == 3}">
      <div class="alert alert-success py-2" role="alert">Formato eliminado.</div>
    </c:if>
    <c:if test="${not empty dbError or not empty dbError2}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <form method="get" action="formatos.jsp" class="tabla-toolbar mb-3">
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
            <th>Nombre</th>
            <th>Descripci&oacute;n</th>
            <th>Categor&iacute;a</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <c:forEach var="f" items="${lista.rows}">
            <tr>
              <td><c:out value="${f.nombre}" /></td>
              <td>
                <c:out value="${fn:substring(f.descripcion, 0, 80)}" /><c:if test="${fn:length(f.descripcion) > 80}">...</c:if>
              </td>
              <td><span class="rol-badge"><c:out value="${f.categoria}" /></span></td>
              <td class="text-nowrap">
                <c:choose>
                  <c:when test="${fn:startsWith(f.enlace, 'http://') or fn:startsWith(f.enlace, 'https://')}">
                    <a href="${fn:escapeXml(f.enlace)}" target="_blank" rel="noopener" class="btn btn-sm btn-lima" title="Abrir"><i class="fa-solid fa-link"></i> Abrir</a>
                  </c:when>
                  <c:otherwise>
                    <span class="text-muted"><c:out value="${f.enlace}" default="Sin enlace" /></span>
                  </c:otherwise>
                </c:choose>
                <c:if test="${puedeGestionar}">
                  <c:url var="urlEditar" value="formato-form.jsp">
                    <c:param name="id" value="${f.id}" />
                  </c:url>
                  <a href="${urlEditar}" class="btn btn-sm btn-lima" title="Editar"><i class="fa-solid fa-pen"></i></a>
                  <button type="button" class="btn btn-sm btn-danger" title="Eliminar"
                          data-bs-toggle="modal" data-bs-target="#modalEliminar${f.id}"><i class="fa-solid fa-trash"></i></button>
                </c:if>
              </td>
            </tr>
            <c:if test="${puedeGestionar}">
              <div class="modal fade" id="modalEliminar${f.id}" tabindex="-1" aria-hidden="true">
                <div class="modal-dialog">
                  <div class="modal-content">
                    <div class="modal-header">
                      <h5 class="modal-title">Confirmar eliminaci&oacute;n</h5>
                      <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                    </div>
                    <div class="modal-body">
                      &iquest;Eliminar el formato <strong><c:out value="${f.nombre}" /></strong>?
                    </div>
                    <div class="modal-footer">
                      <form method="post" action="formato-eliminar.jsp">
                        <input type="hidden" name="id" value="${f.id}" />
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
            <tr><td colspan="4" class="text-center text-muted">A&uacute;n no hay formatos publicados.</td></tr>
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
