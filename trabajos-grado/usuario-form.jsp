<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  usuario-form.jsp (solo ADMINISTRADOR)
  Sin ?id: registra (clave obligatoria, INSERT con SHA2(?,256), redirige ?ok=1).
  Con ?id=X: edita (clave opcional, UPDATE, duplicados excluyendo el propio id,
  redirige ?ok=2). Id inexistente -> redirige a usuarios.jsp.
--%>
<c:set var="activo" value="usuarios" scope="request" />
<c:set var="rolesPermitidos" value="ADMINISTRADOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:set var="esEdicion" value="${not empty param.id}" scope="request" />
<c:set var="esPost" value="${pageContext.request.method == 'POST'}" scope="request" />
<c:set var="titulo" value="${esEdicion ? 'Editar usuario' : 'Nuevo usuario'}" scope="request" />

<c:catch var="dbError">
  <sql:query var="roles" dataSource="${db}">
    SELECT id, nombre FROM roles ORDER BY id
  </sql:query>
</c:catch>

<c:if test="${esEdicion}">
  <c:catch var="editError">
    <sql:query var="editado" dataSource="${db}">
      SELECT u.id, u.codigo, u.nombre, u.correo, u.rol_id, u.estado
      FROM usuarios u WHERE u.id = ?
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${not empty editError or editado.rowCount == 0}">
    <c:redirect url="usuarios.jsp" />
  </c:if>
</c:if>

<c:if test="${esPost}">
  <c:choose>
    <%-- ================= EDICION ================= --%>
    <c:when test="${esEdicion}">
      <c:choose>
        <c:when test="${empty param.codigo or empty param.nombre or empty param.correo or empty param.rol_id or empty param.estado}">
          <c:set var="formError" value="Todos los campos son obligatorios." scope="request" />
        </c:when>
        <c:when test="${(not empty param.password or not empty param.confirmar) and param.password != param.confirmar}">
          <c:set var="formError" value="Las contraseñas no coinciden." scope="request" />
        </c:when>
        <c:otherwise>
          <c:catch var="dupError">
            <sql:query var="dup" dataSource="${db}">
              SELECT id, codigo, correo FROM usuarios
              WHERE (codigo = ? OR correo = ?) AND id <> ?
              <sql:param value="${param.codigo}" />
              <sql:param value="${param.correo}" />
              <sql:param value="${param.id}" />
            </sql:query>
          </c:catch>
          <c:choose>
            <c:when test="${not empty dupError}">
              <c:set var="formError" value="Error de conexión. Intente de nuevo." scope="request" />
            </c:when>
            <c:when test="${dup.rowCount > 0}">
              <c:set var="formError" value="El código o el correo ya están registrados." scope="request" />
              <c:forEach var="d" items="${dup.rows}">
                <c:if test="${d.codigo == param.codigo}">
                  <c:set var="formError" value="El código ya está registrado." scope="request" />
                </c:if>
                <c:if test="${d.correo == param.correo}">
                  <c:set var="formError" value="El correo ya está registrado." scope="request" />
                </c:if>
              </c:forEach>
            </c:when>
            <c:otherwise>
              <c:choose>
                <c:when test="${not empty param.password}">
                  <c:catch var="updError">
                    <sql:update var="n" dataSource="${db}">
                      UPDATE usuarios
                      SET codigo = ?, nombre = ?, correo = ?, password = SHA2(?, 256), rol_id = ?, estado = ?
                      WHERE id = ?
                      <sql:param value="${param.codigo}" />
                      <sql:param value="${param.nombre}" />
                      <sql:param value="${param.correo}" />
                      <sql:param value="${param.password}" />
                      <sql:param value="${param.rol_id}" />
                      <sql:param value="${param.estado}" />
                      <sql:param value="${param.id}" />
                    </sql:update>
                  </c:catch>
                </c:when>
                <c:otherwise>
                  <c:catch var="updError">
                    <sql:update var="n" dataSource="${db}">
                      UPDATE usuarios
                      SET codigo = ?, nombre = ?, correo = ?, rol_id = ?, estado = ?
                      WHERE id = ?
                      <sql:param value="${param.codigo}" />
                      <sql:param value="${param.nombre}" />
                      <sql:param value="${param.correo}" />
                      <sql:param value="${param.rol_id}" />
                      <sql:param value="${param.estado}" />
                      <sql:param value="${param.id}" />
                    </sql:update>
                  </c:catch>
                </c:otherwise>
              </c:choose>
              <c:choose>
                <c:when test="${empty updError}">
                  <c:redirect url="usuarios.jsp?ok=2" />
                </c:when>
                <c:otherwise>
                  <c:set var="formError" value="No se pudo actualizar. Verifique los datos." scope="request" />
                </c:otherwise>
              </c:choose>
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:when>
    <%-- ================= REGISTRO ================= --%>
    <c:otherwise>
      <c:choose>
        <c:when test="${empty param.codigo or empty param.nombre or empty param.correo or empty param.rol_id or empty param.password or empty param.confirmar or empty param.estado}">
          <c:set var="formError" value="Todos los campos son obligatorios." scope="request" />
        </c:when>
        <c:when test="${param.password != param.confirmar}">
          <c:set var="formError" value="Las contraseñas no coinciden." scope="request" />
        </c:when>
        <c:otherwise>
          <c:catch var="dupError">
            <sql:query var="dup" dataSource="${db}">
              SELECT codigo, correo FROM usuarios WHERE codigo = ? OR correo = ?
              <sql:param value="${param.codigo}" />
              <sql:param value="${param.correo}" />
            </sql:query>
          </c:catch>
          <c:choose>
            <c:when test="${not empty dupError}">
              <c:set var="formError" value="Error de conexión. Intente de nuevo." scope="request" />
            </c:when>
            <c:when test="${dup.rowCount > 0}">
              <c:set var="formError" value="El código o el correo ya están registrados." scope="request" />
              <c:forEach var="d" items="${dup.rows}">
                <c:if test="${d.codigo == param.codigo}">
                  <c:set var="formError" value="El código ya está registrado." scope="request" />
                </c:if>
                <c:if test="${d.correo == param.correo}">
                  <c:set var="formError" value="El correo ya está registrado." scope="request" />
                </c:if>
              </c:forEach>
            </c:when>
            <c:otherwise>
              <c:catch var="insError">
                <sql:update var="n" dataSource="${db}">
                  INSERT INTO usuarios (codigo, nombre, correo, password, rol_id, estado)
                  VALUES (?, ?, ?, SHA2(?, 256), ?, ?)
                  <sql:param value="${param.codigo}" />
                  <sql:param value="${param.nombre}" />
                  <sql:param value="${param.correo}" />
                  <sql:param value="${param.password}" />
                  <sql:param value="${param.rol_id}" />
                  <sql:param value="${param.estado}" />
                </sql:update>
              </c:catch>
              <c:choose>
                <c:when test="${empty insError}">
                  <c:redirect url="usuarios.jsp?ok=1" />
                </c:when>
                <c:otherwise>
                  <c:set var="formError" value="No se pudo registrar. Verifique los datos." scope="request" />
                </c:otherwise>
              </c:choose>
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:otherwise>
  </c:choose>
</c:if>

<%-- Valores del formulario: en POST fallido se conserva lo escrito; en GET de edicion, lo de BD --%>
<c:set var="fCodigo" value="${editado.rows[0].codigo}" />
<c:set var="fNombre" value="${editado.rows[0].nombre}" />
<c:set var="fCorreo" value="${editado.rows[0].correo}" />
<c:set var="fRol" value="${editado.rows[0].rol_id}" />
<c:set var="fEstado" value="${editado.rows[0].estado}" />
<c:if test="${empty fEstado}">
  <c:set var="fEstado" value="ACTIVO" />
</c:if>
<c:if test="${esPost}">
  <c:set var="fCodigo" value="${param.codigo}" />
  <c:set var="fNombre" value="${param.nombre}" />
  <c:set var="fCorreo" value="${param.correo}" />
  <c:set var="fRol" value="${param.rol_id}" />
  <c:set var="fEstado" value="${param.estado}" />
</c:if>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">${esEdicion ? 'Editar' : 'Registrar'} <span class="badge-lima">USUARIO</span></h4>
      <a href="usuarios.jsp" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${not empty requestScope.formError}">
      <div class="alert alert-danger py-2" role="alert"><c:out value="${requestScope.formError}" /></div>
    </c:if>
    <c:if test="${not empty dbError}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <form method="post" action="usuario-form.jsp">
      <c:if test="${esEdicion}">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
      </c:if>
      <div class="row g-3">
        <div class="col-md-6">
          <label class="form-label" for="codigo">C&oacute;digo</label>
          <input type="text" class="form-control" id="codigo" name="codigo" required="required"
                 maxlength="20" placeholder="Ej: EST-00001" value="${fn:escapeXml(fCodigo)}" />
        </div>
        <div class="col-md-6">
          <label class="form-label" for="nombre">Nombre</label>
          <input type="text" class="form-control" id="nombre" name="nombre" required="required"
                 maxlength="100" placeholder="Nombre completo" value="${fn:escapeXml(fNombre)}" />
        </div>
        <div class="col-md-6">
          <label class="form-label" for="correo">Correo</label>
          <input type="email" class="form-control" id="correo" name="correo" required="required"
                 maxlength="100" placeholder="Correo institucional" value="${fn:escapeXml(fCorreo)}" />
        </div>
        <div class="col-md-6">
          <label class="form-label" for="rol_id">Rol</label>
          <select class="form-select" id="rol_id" name="rol_id" required="required">
            <option value="">Seleccione un rol</option>
            <c:forEach var="r" items="${roles.rows}">
              <option value="${r.id}" ${fRol == r.id ? 'selected' : ''}><c:out value="${r.nombre}" /></option>
            </c:forEach>
          </select>
        </div>
        <div class="col-md-6">
          <label class="form-label" for="password">Contrase&ntilde;a</label>
          <input type="password" class="form-control" id="password" name="password"
                 ${esEdicion ? '' : 'required="required"'}
                 placeholder="${esEdicion ? 'Déjela en blanco para conservar la actual' : 'Ingrese la contraseña'}" />
        </div>
        <div class="col-md-6">
          <label class="form-label" for="confirmar">Confirmar contrase&ntilde;a</label>
          <input type="password" class="form-control" id="confirmar" name="confirmar"
                 ${esEdicion ? '' : 'required="required"'}
                 placeholder="${esEdicion ? 'Déjela en blanco para conservar la actual' : 'Repita la contraseña'}" />
        </div>
        <div class="col-md-6">
          <label class="form-label" for="estado">Estado</label>
          <select class="form-select" id="estado" name="estado" required="required">
            <option value="ACTIVO" ${fEstado == 'ACTIVO' ? 'selected' : ''}>ACTIVO</option>
            <option value="INACTIVO" ${fEstado == 'INACTIVO' ? 'selected' : ''}>INACTIVO</option>
          </select>
        </div>
      </div>
      <div class="mt-3 d-flex gap-2">
        <button type="submit" class="btn btn-lima"><i class="fa-solid fa-floppy-disk"></i> Guardar</button>
        <a href="usuarios.jsp" class="btn btn-outline-secondary">Cancelar</a>
      </div>
    </form>
  </div>
</div>

<c:import url="includes/footer.jsp" />
