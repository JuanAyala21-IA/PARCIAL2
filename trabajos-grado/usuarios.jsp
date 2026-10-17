<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  usuarios.jsp (solo ADMINISTRADOR)
  Lista con busqueda (codigo/nombre/correo), tamano de pagina y paginacion por GET.
  Dos consultas: COUNT para el total de paginas y SELECT con LIMIT/OFFSET.
--%>
<c:set var="titulo" value="Usuarios" scope="request" />
<c:set var="activo" value="usuarios" scope="request" />
<c:set var="rolesPermitidos" value="ADMINISTRADOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

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
    SELECT COUNT(*) AS total FROM usuarios u
    WHERE (COALESCE(u.codigo, '') LIKE ? OR u.nombre LIKE ? OR u.correo LIKE ?)
    <sql:param value="${patron}" />
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
    SELECT u.id, u.codigo, u.nombre, u.correo, u.estado,
           (SELECT r.nombre FROM roles r WHERE r.id = u.rol_id) AS rol
    FROM usuarios u
    WHERE (COALESCE(u.codigo, '') LIKE ? OR u.nombre LIKE ? OR u.correo LIKE ?)
    ORDER BY u.id DESC LIMIT ? OFFSET ?
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${patron}" />
    <sql:param value="${tam}" />
    <sql:param value="${ini}" />
  </sql:query>
</c:catch>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<c:url var="urlPrimera" value="usuarios.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="1" />
</c:url>
<c:url var="urlAnterior" value="usuarios.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="${pag - 1}" />
</c:url>
<c:url var="urlSiguiente" value="usuarios.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="${pag + 1}" />
</c:url>
<c:url var="urlUltima" value="usuarios.jsp">
  <c:param name="q" value="${param.q}" />
  <c:param name="size" value="${tam}" />
  <c:param name="page" value="${totalPag}" />
</c:url>

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Usuarios del <span class="badge-lima">SISTEMA</span></h4>
      <a href="usuario-form.jsp" class="btn btn-lima"><i class="fa-solid fa-plus"></i> Nuevo usuario</a>
    </div>
    <hr />

    <c:if test="${param.ok == 1}">
      <div class="alert alert-success py-2" role="alert">Usuario registrado.</div>
    </c:if>
    <c:if test="${param.ok == 2}">
      <div class="alert alert-success py-2" role="alert">Usuario actualizado.</div>
    </c:if>
    <c:if test="${param.ok == 3}">
      <div class="alert alert-success py-2" role="alert">Usuario eliminado.</div>
    </c:if>
    <c:if test="${param.ok == 12}">
      <div class="alert alert-success py-2" role="alert">Estado del usuario actualizado.</div>
    </c:if>
    <c:if test="${not empty sessionScope.flashUsuarios}">
      <div class="alert alert-success py-2" role="alert"><c:out value="${sessionScope.flashUsuarios}" /></div>
      <c:remove var="flashUsuarios" scope="session" />
    </c:if>
    <c:if test="${param.error == 'propio'}">
      <div class="alert alert-danger py-2" role="alert">No puedes eliminarte a ti mismo.</div>
    </c:if>
    <c:if test="${param.error == 'ultimo-admin'}">
      <div class="alert alert-danger py-2" role="alert">No puedes eliminar al &uacute;nico administrador.</div>
    </c:if>
    <c:if test="${param.error == 'relacionado'}">
      <div class="alert alert-warning py-2" role="alert">El usuario tiene registros relacionados. <a href="usuario-eliminar-confirmar.jsp?id=${param.id}" class="alert-link">Revisar la eliminaci&oacute;n definitiva</a>.</div>
    </c:if>
    <c:if test="${not empty dbError or not empty dbError2}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <form method="get" action="usuarios.jsp" class="tabla-toolbar mb-3">
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
            <th>C&oacute;digo</th>
            <th>Nombre</th>
            <th>Correo</th>
            <th>Rol</th>
            <th>Estado</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <c:forEach var="u" items="${lista.rows}">
            <tr>
              <td><c:out value="${u.codigo}" default="&#8212;" /></td>
              <td><c:out value="${u.nombre}" /></td>
              <td><c:out value="${u.correo}" /></td>
              <td><span class="rol-badge"><c:out value="${u.rol}" /></span></td>
              <td>
                <c:if test="${u.estado == 'ACTIVO'}">
                  <span class="badge text-bg-success">ACTIVO</span>
                </c:if>
                <c:if test="${u.estado != 'ACTIVO'}">
                  <span class="badge text-bg-secondary"><c:out value="${u.estado}" /></span>
                </c:if>
              </td>
              <td class="text-nowrap">
                <c:url var="urlVer" value="usuario-ver.jsp">
                  <c:param name="id" value="${u.id}" />
                </c:url>
                <c:url var="urlEditar" value="usuario-form.jsp">
                  <c:param name="id" value="${u.id}" />
                </c:url>
                <a href="${urlVer}" class="btn btn-sm btn-dark" title="Ver"><i class="fa-solid fa-eye"></i></a>
                <a href="${urlEditar}" class="btn btn-sm btn-lima" title="Editar"><i class="fa-solid fa-pen"></i></a>
                <c:choose>
                  <c:when test="${u.id == sessionScope.usuarioId}">
                    <button type="button" class="btn btn-sm btn-danger" title="No puedes eliminarte a ti mismo" disabled><i class="fa-solid fa-trash"></i></button>
                  </c:when>
                  <c:otherwise>
                    <button type="button" class="btn btn-sm btn-danger" title="Eliminar"
                            data-bs-toggle="modal" data-bs-target="#modalEliminar${u.id}"><i class="fa-solid fa-trash"></i></button>
                  </c:otherwise>
                </c:choose>
              </td>
            </tr>
            <c:if test="${u.id != sessionScope.usuarioId}">
            <div class="modal fade" id="modalEliminar${u.id}" tabindex="-1" aria-hidden="true">
              <div class="modal-dialog">
                <div class="modal-content">
                  <div class="modal-header">
                    <h5 class="modal-title">Confirmar eliminaci&oacute;n</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                  </div>
                  <div class="modal-body">
                    &iquest;Eliminar a <strong><c:out value="${u.nombre}" /></strong>?
                  </div>
                  <div class="modal-footer">
                    <form method="post" action="usuario-eliminar.jsp">
                      <input type="hidden" name="id" value="${u.id}" />
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
            <tr><td colspan="6" class="text-center text-muted">Sin resultados.</td></tr>
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
