<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  idea-form.jsp (solo COORDINACION)
  Sin ?id: crea (estado DISPONIBLE, propuesta_por = usuario en sesion, ?ok=1).
  Con ?id=X: edita (?ok=2). Id inexistente -> redirige a ideas.jsp.
--%>
<c:set var="activo" value="ideas" scope="request" />
<c:set var="rolesPermitidos" value="COORDINACION" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:set var="esEdicion" value="${not empty param.id}" scope="request" />
<c:set var="esPost" value="${pageContext.request.method == 'POST'}" scope="request" />
<c:set var="titulo" value="${esEdicion ? 'Editar idea' : 'Nueva idea'}" scope="request" />

<c:if test="${esEdicion}">
  <c:catch var="editError">
    <sql:query var="editada" dataSource="${db}">
      SELECT i.id, i.titulo, i.descripcion, i.area, i.estado
      FROM ideas i WHERE i.id = ?
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${not empty editError or editada.rowCount == 0}">
    <c:redirect url="ideas.jsp" />
  </c:if>
  <%-- Las ideas POSTULADA por estudiantes solo se gestionan desde la solicitud (Fase 1) --%>
  <c:if test="${editada.rows[0].estado == 'POSTULADA'}">
    <c:redirect url="ideas.jsp?error=postulada" />
  </c:if>
</c:if>

<c:if test="${esPost}">
  <c:choose>
    <c:when test="${empty param.titulo or empty param.descripcion}">
      <c:set var="formError" value="El título y la descripción son obligatorios." scope="request" />
    </c:when>
    <c:otherwise>
      <c:choose>
        <c:when test="${esEdicion}">
          <c:catch var="updError">
            <sql:update var="n" dataSource="${db}">
              UPDATE ideas SET titulo = ?, descripcion = ?, area = ?, estado = ? WHERE id = ?
              <sql:param value="${param.titulo}" />
              <sql:param value="${param.descripcion}" />
              <sql:param value="${param.area}" />
              <sql:param value="${param.estado}" />
              <sql:param value="${param.id}" />
            </sql:update>
          </c:catch>
          <c:choose>
            <c:when test="${empty updError}">
              <c:redirect url="ideas.jsp?ok=2" />
            </c:when>
            <c:otherwise>
              <c:set var="formError" value="No se pudo actualizar. Verifique los datos." scope="request" />
            </c:otherwise>
          </c:choose>
        </c:when>
        <c:otherwise>
          <c:catch var="insError">
            <sql:update var="n" dataSource="${db}">
              INSERT INTO ideas (titulo, descripcion, area, propuesta_por, estado)
              VALUES (?, ?, ?, ?, 'DISPONIBLE')
              <sql:param value="${param.titulo}" />
              <sql:param value="${param.descripcion}" />
              <sql:param value="${param.area}" />
              <sql:param value="${sessionScope.usuarioId}" />
            </sql:update>
          </c:catch>
          <c:choose>
            <c:when test="${empty insError}">
              <c:redirect url="ideas.jsp?ok=1" />
            </c:when>
            <c:otherwise>
              <c:set var="formError" value="No se pudo registrar. Verifique los datos." scope="request" />
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:otherwise>
  </c:choose>
</c:if>

<%-- Valores del formulario: en POST fallido se conserva lo escrito; en GET de edicion, lo de BD --%>
<c:set var="fTitulo" value="${editada.rows[0].titulo}" />
<c:set var="fDescripcion" value="${editada.rows[0].descripcion}" />
<c:set var="fArea" value="${editada.rows[0].area}" />
<c:set var="fEstado" value="${editada.rows[0].estado}" />
<c:if test="${empty fEstado}">
  <c:set var="fEstado" value="DISPONIBLE" />
</c:if>
<c:if test="${esPost}">
  <c:set var="fTitulo" value="${param.titulo}" />
  <c:set var="fDescripcion" value="${param.descripcion}" />
  <c:set var="fArea" value="${param.area}" />
  <c:set var="fEstado" value="${param.estado}" />
</c:if>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">${esEdicion ? 'Editar' : 'Registrar'} <span class="badge-lima">IDEA</span></h4>
      <a href="ideas.jsp" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${not empty requestScope.formError}">
      <div class="alert alert-danger py-2" role="alert"><c:out value="${requestScope.formError}" /></div>
    </c:if>

    <form method="post" action="idea-form.jsp">
      <c:if test="${esEdicion}">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
      </c:if>
      <div class="row g-3">
        <div class="col-12">
          <label class="form-label" for="titulo">T&iacute;tulo</label>
          <input type="text" class="form-control" id="titulo" name="titulo" required="required"
                 maxlength="200" placeholder="Título de la idea" value="${fn:escapeXml(fTitulo)}" />
        </div>
        <div class="col-12">
          <label class="form-label" for="descripcion">Descripci&oacute;n</label>
          <textarea class="form-control" id="descripcion" name="descripcion" rows="4" required="required"
                    placeholder="Describa la idea del anteproyecto"><c:out value="${fDescripcion}" /></textarea>
        </div>
        <div class="col-md-6">
          <label class="form-label" for="area">&Aacute;rea</label>
          <input type="text" class="form-control" id="area" name="area"
                 maxlength="100" placeholder="Ej: Inteligencia artificial" value="${fn:escapeXml(fArea)}" />
        </div>
        <c:if test="${esEdicion}">
          <div class="col-md-6">
            <label class="form-label" for="estado">Estado</label>
            <select class="form-select" id="estado" name="estado" required="required">
              <option value="DISPONIBLE" ${fEstado == 'DISPONIBLE' ? 'selected' : ''}>DISPONIBLE</option>
              <option value="ASIGNADA" ${fEstado == 'ASIGNADA' ? 'selected' : ''}>ASIGNADA</option>
              <option value="INACTIVA" ${fEstado == 'INACTIVA' ? 'selected' : ''}>INACTIVA</option>
            </select>
          </div>
        </c:if>
      </div>
      <div class="mt-3 d-flex gap-2">
        <button type="submit" class="btn btn-lima"><i class="fa-solid fa-floppy-disk"></i> Guardar</button>
        <a href="ideas.jsp" class="btn btn-outline-secondary">Cancelar</a>
      </div>
    </form>
  </div>
</div>

<c:import url="includes/footer.jsp" />
