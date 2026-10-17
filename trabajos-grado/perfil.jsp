<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  perfil.jsp (cualquier usuario autenticado)
  Tarjeta de solo lectura con mis datos y tarjeta para cambiar contraseña.
  Nombre, correo y rol no se editan aquí (eso es del administrador).
  Las contraseñas nunca se reimprimen.
--%>
<c:set var="titulo" value="Mi perfil" scope="request" />
<c:set var="activo" value="perfil" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:catch var="dbError">
  <sql:query var="yo" dataSource="${db}">
    SELECT u.codigo, u.nombre, u.correo, u.estado,
           (SELECT r.nombre FROM roles r WHERE r.id = u.rol_id) AS rol
    FROM usuarios u
    WHERE u.id = ?
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
</c:catch>
<c:if test="${empty dbError and yo.rowCount == 0}">
  <c:redirect url="logout.jsp" />
</c:if>

<c:if test="${pageContext.request.method == 'POST'}">
  <c:choose>
    <c:when test="${empty param.actual or empty param.nueva or empty param.confirmar}">
      <c:set var="formError" value="Todos los campos son obligatorios." scope="request" />
    </c:when>
    <c:when test="${param.nueva != param.confirmar}">
      <c:set var="formError" value="La nueva contraseña y la confirmación no coinciden." scope="request" />
    </c:when>
    <c:when test="${fn:length(param.nueva) < 6}">
      <c:set var="formError" value="La nueva contraseña debe tener mínimo 6 caracteres." scope="request" />
    </c:when>
    <c:otherwise>
      <c:catch var="verError">
        <sql:query var="ok" dataSource="${db}">
          SELECT id FROM usuarios WHERE id = ? AND password = SHA2(?, 256)
          <sql:param value="${sessionScope.usuarioId}" />
          <sql:param value="${param.actual}" />
        </sql:query>
      </c:catch>
      <c:choose>
        <c:when test="${not empty verError}">
          <c:set var="formError" value="Error de conexión. Intente de nuevo." scope="request" />
        </c:when>
        <c:when test="${ok.rowCount == 0}">
          <c:set var="formError" value="La contraseña actual no es correcta." scope="request" />
        </c:when>
        <c:otherwise>
          <c:catch var="updError">
            <sql:update var="n" dataSource="${db}">
              UPDATE usuarios SET password = SHA2(?, 256) WHERE id = ?
              <sql:param value="${param.nueva}" />
              <sql:param value="${sessionScope.usuarioId}" />
            </sql:update>
          </c:catch>
          <c:choose>
            <c:when test="${empty updError}">
              <c:redirect url="perfil.jsp?ok=1" />
            </c:when>
            <c:otherwise>
              <c:set var="formError" value="No se pudo actualizar. Intente de nuevo." scope="request" />
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:otherwise>
  </c:choose>
</c:if>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Mi <span class="badge-lima">PERFIL</span></h4>
    </div>
    <hr />

    <c:if test="${param.ok == 1}">
      <div class="alert alert-success py-2" role="alert">Contrase&ntilde;a actualizada.</div>
    </c:if>
    <c:if test="${not empty requestScope.formError}">
      <div class="alert alert-danger py-2" role="alert"><c:out value="${requestScope.formError}" /></div>
    </c:if>
    <c:if test="${not empty dbError}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <dl class="row mb-0">
      <dt class="col-sm-3">C&oacute;digo</dt>
      <dd class="col-sm-9"><c:out value="${yo.rows[0].codigo}" default="&#8212;" /></dd>
      <dt class="col-sm-3">Nombre</dt>
      <dd class="col-sm-9"><c:out value="${yo.rows[0].nombre}" /></dd>
      <dt class="col-sm-3">Correo</dt>
      <dd class="col-sm-9"><c:out value="${yo.rows[0].correo}" /></dd>
      <dt class="col-sm-3">Rol</dt>
      <dd class="col-sm-9"><span class="rol-badge"><c:out value="${yo.rows[0].rol}" /></span></dd>
      <dt class="col-sm-3">Estado</dt>
      <dd class="col-sm-9">
        <c:if test="${yo.rows[0].estado == 'ACTIVO'}">
          <span class="badge text-bg-success">ACTIVO</span>
        </c:if>
        <c:if test="${yo.rows[0].estado != 'ACTIVO'}">
          <span class="badge text-bg-secondary"><c:out value="${yo.rows[0].estado}" /></span>
        </c:if>
      </dd>
    </dl>
  </div>
</div>

<div class="card card-lima shadow-sm mt-3">
  <div class="card-body">
    <h5 class="mb-3">Cambiar contrase&ntilde;a</h5>
    <form method="post" action="perfil.jsp">
      <div class="row g-3">
        <div class="col-md-4">
          <label class="form-label" for="actual">Contrase&ntilde;a actual</label>
          <input type="password" class="form-control" id="actual" name="actual" required="required"
                 placeholder="Ingrese su contraseña actual" />
        </div>
        <div class="col-md-4">
          <label class="form-label" for="nueva">Nueva contrase&ntilde;a</label>
          <input type="password" class="form-control" id="nueva" name="nueva" required="required"
                 placeholder="Mínimo 6 caracteres" />
        </div>
        <div class="col-md-4">
          <label class="form-label" for="confirmar">Confirmar nueva</label>
          <input type="password" class="form-control" id="confirmar" name="confirmar" required="required"
                 placeholder="Repita la nueva contraseña" />
        </div>
      </div>
      <div class="mt-3">
        <button type="submit" class="btn btn-lima"><i class="fa-solid fa-key"></i> Actualizar contrase&ntilde;a</button>
      </div>
    </form>
  </div>
</div>

<c:import url="includes/footer.jsp" />
