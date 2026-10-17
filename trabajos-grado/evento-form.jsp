<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  evento-form.jsp (solo COORDINACION y ADMINISTRADOR)
  Sin ?id: crea (?ok=1). Con ?id=X: edita (?ok=2).
  fecha_fin opcional, no menor que inicio. Id inexistente -> calendario.jsp.
--%>
<c:set var="activo" value="calendario" scope="request" />
<c:set var="rolesPermitidos" value="COORDINACION,ADMINISTRADOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:set var="esEdicion" value="${not empty param.id}" scope="request" />
<c:set var="esPost" value="${pageContext.request.method == 'POST'}" scope="request" />
<c:set var="titulo" value="${esEdicion ? 'Editar evento' : 'Nuevo evento'}" scope="request" />

<c:if test="${esEdicion}">
  <c:catch var="editError">
    <sql:query var="editado" dataSource="${db}">
      SELECT id, titulo, descripcion, tipo, fecha_inicio, fecha_fin
      FROM calendario WHERE id = ?
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${not empty editError or editado.rowCount == 0}">
    <c:redirect url="calendario.jsp" />
  </c:if>
</c:if>

<c:if test="${esPost}">
  <c:choose>
    <c:when test="${empty param.titulo or empty param.tipo or empty param.fecha_inicio}">
      <c:set var="formError" value="Título, tipo y fecha de inicio son obligatorios." scope="request" />
    </c:when>
    <c:when test="${param.tipo != 'ENTREGA' and param.tipo != 'REUNION' and param.tipo != 'SUSTENTACION' and param.tipo != 'OTRO'}">
      <c:set var="formError" value="El tipo no es válido." scope="request" />
    </c:when>
    <c:when test="${not empty param.fecha_fin and param.fecha_fin < param.fecha_inicio}">
      <c:set var="formError" value="La fecha de fin no puede ser menor que la de inicio." scope="request" />
    </c:when>
    <c:otherwise>
      <c:set var="tieneFin" value="${not empty param.fecha_fin}" />
      <c:choose>
        <c:when test="${esEdicion and tieneFin}">
          <c:catch var="saveError">
            <sql:update var="n" dataSource="${db}">
              UPDATE calendario SET titulo = ?, actividad = ?, descripcion = ?, tipo = ?, fecha_inicio = ?, fecha_fin = ?
              WHERE id = ?
              <sql:param value="${param.titulo}" />
              <sql:param value="${param.titulo}" />
              <sql:param value="${param.descripcion}" />
              <sql:param value="${param.tipo}" />
              <sql:param value="${param.fecha_inicio}" />
              <sql:param value="${param.fecha_fin}" />
              <sql:param value="${param.id}" />
            </sql:update>
          </c:catch>
        </c:when>
        <c:when test="${esEdicion}">
          <c:catch var="saveError">
            <sql:update var="n" dataSource="${db}">
              UPDATE calendario SET titulo = ?, actividad = ?, descripcion = ?, tipo = ?, fecha_inicio = ?, fecha_fin = NULL
              WHERE id = ?
              <sql:param value="${param.titulo}" />
              <sql:param value="${param.titulo}" />
              <sql:param value="${param.descripcion}" />
              <sql:param value="${param.tipo}" />
              <sql:param value="${param.fecha_inicio}" />
              <sql:param value="${param.id}" />
            </sql:update>
          </c:catch>
        </c:when>
        <c:when test="${tieneFin}">
          <c:catch var="saveError">
            <sql:update var="n" dataSource="${db}">
              INSERT INTO calendario (titulo, actividad, descripcion, tipo, fecha_inicio, fecha_fin)
              VALUES (?, ?, ?, ?, ?, ?)
              <sql:param value="${param.titulo}" />
              <sql:param value="${param.titulo}" />
              <sql:param value="${param.descripcion}" />
              <sql:param value="${param.tipo}" />
              <sql:param value="${param.fecha_inicio}" />
              <sql:param value="${param.fecha_fin}" />
            </sql:update>
          </c:catch>
        </c:when>
        <c:otherwise>
          <c:catch var="saveError">
            <sql:update var="n" dataSource="${db}">
              INSERT INTO calendario (titulo, actividad, descripcion, tipo, fecha_inicio)
              VALUES (?, ?, ?, ?, ?)
              <sql:param value="${param.titulo}" />
              <sql:param value="${param.titulo}" />
              <sql:param value="${param.descripcion}" />
              <sql:param value="${param.tipo}" />
              <sql:param value="${param.fecha_inicio}" />
            </sql:update>
          </c:catch>
        </c:otherwise>
      </c:choose>
      <c:choose>
        <c:when test="${empty saveError}">
          <c:redirect url="calendario.jsp?ok=${esEdicion ? 2 : 1}" />
        </c:when>
        <c:otherwise>
          <c:set var="formError" value="No se pudo guardar. Verifique los datos." scope="request" />
        </c:otherwise>
      </c:choose>
    </c:otherwise>
  </c:choose>
</c:if>

<%-- Valores: en POST fallido lo escrito; en GET de edición, lo de BD --%>
<fmt:formatDate var="dbIni" value="${editado.rows[0].fecha_inicio}" pattern="yyyy-MM-dd" />
<fmt:formatDate var="dbFin" value="${editado.rows[0].fecha_fin}" pattern="yyyy-MM-dd" />
<c:set var="fTitulo" value="${editado.rows[0].titulo}" />
<c:set var="fDesc" value="${editado.rows[0].descripcion}" />
<c:set var="fTipo" value="${editado.rows[0].tipo}" />
<c:set var="fIni" value="${dbIni}" />
<c:set var="fFin" value="${dbFin}" />
<c:if test="${empty fTipo}">
  <c:set var="fTipo" value="OTRO" />
</c:if>
<c:if test="${esPost}">
  <c:set var="fTitulo" value="${param.titulo}" />
  <c:set var="fDesc" value="${param.descripcion}" />
  <c:set var="fTipo" value="${param.tipo}" />
  <c:set var="fIni" value="${param.fecha_inicio}" />
  <c:set var="fFin" value="${param.fecha_fin}" />
</c:if>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">${esEdicion ? 'Editar' : 'Registrar'} <span class="badge-lima">EVENTO</span></h4>
      <a href="calendario.jsp" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${not empty requestScope.formError}">
      <div class="alert alert-danger py-2" role="alert"><c:out value="${requestScope.formError}" /></div>
    </c:if>

    <form method="post" action="evento-form.jsp">
      <c:if test="${esEdicion}">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
      </c:if>
      <div class="row g-3">
        <div class="col-12">
          <label class="form-label" for="titulo">T&iacute;tulo</label>
          <input type="text" class="form-control" id="titulo" name="titulo" required="required"
                 maxlength="200" placeholder="Título del evento" value="${fn:escapeXml(fTitulo)}" />
        </div>
        <div class="col-12">
          <label class="form-label" for="descripcion">Descripci&oacute;n</label>
          <textarea class="form-control" id="descripcion" name="descripcion" rows="3"
                    placeholder="Descripción opcional"><c:out value="${fDesc}" /></textarea>
        </div>
        <div class="col-md-4">
          <label class="form-label" for="tipo">Tipo</label>
          <select class="form-select" id="tipo" name="tipo" required="required">
            <option value="ENTREGA" ${fTipo == 'ENTREGA' ? 'selected' : ''}>ENTREGA</option>
            <option value="REUNION" ${fTipo == 'REUNION' ? 'selected' : ''}>REUNI&Oacute;N</option>
            <option value="SUSTENTACION" ${fTipo == 'SUSTENTACION' ? 'selected' : ''}>SUSTENTACI&Oacute;N</option>
            <option value="OTRO" ${fTipo == 'OTRO' ? 'selected' : ''}>OTRO</option>
          </select>
        </div>
        <div class="col-md-4">
          <label class="form-label" for="fecha_inicio">Fecha de inicio</label>
          <input type="date" class="form-control" id="fecha_inicio" name="fecha_inicio" required="required"
                 value="${fn:escapeXml(fIni)}" />
        </div>
        <div class="col-md-4">
          <label class="form-label" for="fecha_fin">Fecha de fin (opcional)</label>
          <input type="date" class="form-control" id="fecha_fin" name="fecha_fin"
                 value="${fn:escapeXml(fFin)}" />
        </div>
      </div>
      <div class="mt-3 d-flex gap-2">
        <button type="submit" class="btn btn-lima"><i class="fa-solid fa-floppy-disk"></i> Guardar</button>
        <a href="calendario.jsp" class="btn btn-outline-secondary">Cancelar</a>
      </div>
    </form>
  </div>
</div>

<c:import url="includes/footer.jsp" />
