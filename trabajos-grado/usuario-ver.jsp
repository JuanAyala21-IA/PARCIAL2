<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  usuario-ver.jsp (solo ADMINISTRADOR)
  Tarjeta de solo lectura con los datos del usuario.
  Si el id no existe, redirige a usuarios.jsp.
  (La tabla usuarios no tiene fecha de creacion, por eso no se muestra.)
--%>
<c:set var="titulo" value="Ver usuario" scope="request" />
<c:set var="activo" value="usuarios" scope="request" />
<c:set var="rolesPermitidos" value="ADMINISTRADOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${empty param.id}">
  <c:redirect url="usuarios.jsp" />
</c:if>
<c:catch var="dbError">
  <sql:query var="ver" dataSource="${db}">
    SELECT u.id, u.codigo, u.nombre, u.correo, u.estado,
           (SELECT r.nombre FROM roles r WHERE r.id = u.rol_id) AS rol
    FROM usuarios u
    WHERE u.id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${empty dbError and ver.rowCount == 0}">
  <c:redirect url="usuarios.jsp" />
</c:if>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<c:url var="urlEditar" value="usuario-form.jsp">
  <c:param name="id" value="${ver.rows[0].id}" />
</c:url>

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Detalle del <span class="badge-lima">USUARIO</span></h4>
      <a href="usuarios.jsp" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${not empty dbError}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <c:if test="${not empty dbError or ver.rowCount == 0}">
      <p class="text-muted">No se pudo cargar el usuario.</p>
    </c:if>
    <c:if test="${empty dbError and ver.rowCount == 1}">
      <dl class="row mb-0">
        <dt class="col-sm-3">C&oacute;digo</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].codigo}" default="&#8212;" /></dd>
        <dt class="col-sm-3">Nombre</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].nombre}" /></dd>
        <dt class="col-sm-3">Correo</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].correo}" /></dd>
        <dt class="col-sm-3">Rol</dt>
        <dd class="col-sm-9"><span class="rol-badge"><c:out value="${ver.rows[0].rol}" /></span></dd>
        <dt class="col-sm-3">Estado</dt>
        <dd class="col-sm-9">
          <c:if test="${ver.rows[0].estado == 'ACTIVO'}">
            <span class="badge text-bg-success">ACTIVO</span>
          </c:if>
          <c:if test="${ver.rows[0].estado != 'ACTIVO'}">
            <span class="badge text-bg-secondary"><c:out value="${ver.rows[0].estado}" /></span>
          </c:if>
        </dd>
      </dl>
      <div class="mt-3 d-flex gap-2">
        <a href="${urlEditar}" class="btn btn-lima"><i class="fa-solid fa-pen"></i> Editar</a>
        <c:if test="${ver.rows[0].id != sessionScope.usuarioId}">
          <button type="button" class="btn btn-danger" data-bs-toggle="modal" data-bs-target="#modalEliminarUsuario"><i class="fa-solid fa-trash"></i> Eliminar usuario</button>
        </c:if>
        <a href="usuarios.jsp" class="btn btn-outline-secondary">Volver</a>
      </div>
    </c:if>
  </div>
</div>

<c:if test="${empty dbError and ver.rowCount == 1 and ver.rows[0].id != sessionScope.usuarioId}">
  <div class="modal fade" id="modalEliminarUsuario" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">Confirmar eliminaci&oacute;n</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
        </div>
        <div class="modal-body">
          &iquest;Eliminar a <strong><c:out value="${ver.rows[0].nombre}" /></strong>?
        </div>
        <div class="modal-footer">
          <form method="post" action="usuario-eliminar.jsp">
            <input type="hidden" name="id" value="${ver.rows[0].id}" />
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
            <button type="submit" class="btn btn-danger">Eliminar</button>
          </form>
        </div>
      </div>
    </div>
  </div>
</c:if>

<c:import url="includes/footer.jsp" />
