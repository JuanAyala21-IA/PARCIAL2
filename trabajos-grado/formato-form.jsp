<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  formato-form.jsp (solo COORDINACION y ADMINISTRADOR)
  Sin ?id: crea (?ok=1). Con ?id=X: edita (?ok=2).
  Enlace obligatorio http(s), máx. 500. Id inexistente -> formatos.jsp.
--%>
<c:set var="activo" value="documental" scope="request" />
<c:set var="rolesPermitidos" value="COORDINACION,ADMINISTRADOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:set var="esEdicion" value="${not empty param.id}" scope="request" />
<c:set var="esPost" value="${pageContext.request.method == 'POST'}" scope="request" />
<c:set var="titulo" value="${esEdicion ? 'Editar formato' : 'Nuevo formato'}" scope="request" />

<c:if test="${esEdicion}">
  <c:catch var="editError">
    <sql:query var="editado" dataSource="${db}">
      SELECT id, nombre, descripcion, categoria, enlace
      FROM formatos WHERE id = ?
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${not empty editError or editado.rowCount == 0}">
    <c:redirect url="formatos.jsp" />
  </c:if>
</c:if>

<c:if test="${esPost}">
  <c:choose>
    <c:when test="${empty param.nombre or empty param.enlace}">
      <c:set var="formError" value="El nombre y el enlace son obligatorios." scope="request" />
    </c:when>
    <c:when test="${param.categoria != 'ANTEPROYECTO' and param.categoria != 'INFORME' and param.categoria != 'SUSTENTACION' and param.categoria != 'OTRO'}">
      <c:set var="formError" value="La categoría no es válida." scope="request" />
    </c:when>
    <c:when test="${not fn:startsWith(param.enlace, 'http://') and not fn:startsWith(param.enlace, 'https://')}">
      <c:set var="formError" value="El enlace debe empezar con http:// o https://." scope="request" />
    </c:when>
    <c:when test="${fn:length(param.enlace) > 500}">
      <c:set var="formError" value="El enlace no puede superar 500 caracteres." scope="request" />
    </c:when>
    <c:otherwise>
      <c:choose>
        <c:when test="${esEdicion}">
          <c:catch var="saveError">
            <sql:update var="n" dataSource="${db}">
              UPDATE formatos SET nombre = ?, descripcion = ?, categoria = ?, enlace = ?
              WHERE id = ?
              <sql:param value="${param.nombre}" />
              <sql:param value="${param.descripcion}" />
              <sql:param value="${param.categoria}" />
              <sql:param value="${param.enlace}" />
              <sql:param value="${param.id}" />
            </sql:update>
          </c:catch>
        </c:when>
        <c:otherwise>
          <c:catch var="saveError">
            <sql:update var="n" dataSource="${db}">
              INSERT INTO formatos (nombre, descripcion, categoria, enlace)
              VALUES (?, ?, ?, ?)
              <sql:param value="${param.nombre}" />
              <sql:param value="${param.descripcion}" />
              <sql:param value="${param.categoria}" />
              <sql:param value="${param.enlace}" />
            </sql:update>
          </c:catch>
        </c:otherwise>
      </c:choose>
      <c:choose>
        <c:when test="${empty saveError}">
          <c:redirect url="formatos.jsp?ok=${esEdicion ? 2 : 1}" />
        </c:when>
        <c:otherwise>
          <c:set var="formError" value="No se pudo guardar. Verifique los datos." scope="request" />
        </c:otherwise>
      </c:choose>
    </c:otherwise>
  </c:choose>
</c:if>

<%-- Valores: en POST fallido lo escrito; en GET de edición, lo de BD --%>
<c:set var="fNombre" value="${editado.rows[0].nombre}" />
<c:set var="fDesc" value="${editado.rows[0].descripcion}" />
<c:set var="fCat" value="${editado.rows[0].categoria}" />
<c:set var="fEnlace" value="${editado.rows[0].enlace}" />
<c:if test="${empty fCat}">
  <c:set var="fCat" value="OTRO" />
</c:if>
<c:if test="${esPost}">
  <c:set var="fNombre" value="${param.nombre}" />
  <c:set var="fDesc" value="${param.descripcion}" />
  <c:set var="fCat" value="${param.categoria}" />
  <c:set var="fEnlace" value="${param.enlace}" />
</c:if>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">${esEdicion ? 'Editar' : 'Registrar'} <span class="badge-lima">FORMATO</span></h4>
      <a href="formatos.jsp" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${not empty requestScope.formError}">
      <div class="alert alert-danger py-2" role="alert"><c:out value="${requestScope.formError}" /></div>
    </c:if>

    <form method="post" action="formato-form.jsp">
      <c:if test="${esEdicion}">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
      </c:if>
      <div class="row g-3">
        <div class="col-md-6">
          <label class="form-label" for="nombre">Nombre</label>
          <input type="text" class="form-control" id="nombre" name="nombre" required="required"
                 maxlength="100" placeholder="Nombre del formato" value="${fn:escapeXml(fNombre)}" />
        </div>
        <div class="col-md-6">
          <label class="form-label" for="categoria">Categor&iacute;a</label>
          <select class="form-select" id="categoria" name="categoria" required="required">
            <option value="ANTEPROYECTO" ${fCat == 'ANTEPROYECTO' ? 'selected' : ''}>ANTEPROYECTO</option>
            <option value="INFORME" ${fCat == 'INFORME' ? 'selected' : ''}>INFORME</option>
            <option value="SUSTENTACION" ${fCat == 'SUSTENTACION' ? 'selected' : ''}>SUSTENTACI&Oacute;N</option>
            <option value="OTRO" ${fCat == 'OTRO' ? 'selected' : ''}>OTRO</option>
          </select>
        </div>
        <div class="col-12">
          <label class="form-label" for="descripcion">Descripci&oacute;n</label>
          <textarea class="form-control" id="descripcion" name="descripcion" rows="3"
                    placeholder="Descripción opcional"><c:out value="${fDesc}" /></textarea>
        </div>
        <div class="col-12">
          <label class="form-label" for="enlace">Enlace</label>
          <input type="url" class="form-control" id="enlace" name="enlace" required="required"
                 maxlength="500" placeholder="https://..."
                 value="${fn:escapeXml(fEnlace)}" />
        </div>
      </div>
      <div class="mt-3 d-flex gap-2">
        <button type="submit" class="btn btn-lima"><i class="fa-solid fa-floppy-disk"></i> Guardar</button>
        <a href="formatos.jsp" class="btn btn-outline-secondary">Cancelar</a>
      </div>
    </form>
  </div>
</div>

<c:import url="includes/footer.jsp" />
