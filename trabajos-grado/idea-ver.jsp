<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%--
  idea-ver.jsp (todos los roles autenticados, solo lectura)
  Si el id no existe, redirige a ideas.jsp.
--%>
<c:set var="titulo" value="Ver idea" scope="request" />
<c:set var="activo" value="ideas" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${empty param.id}">
  <c:redirect url="ideas.jsp" />
</c:if>
<c:catch var="dbError">
  <sql:query var="ver" dataSource="${db}">
    SELECT i.id, i.titulo, i.descripcion, i.area, i.estado, i.propuesta_por, i.fecha_registro,
           DATE_FORMAT(i.fecha_registro, '%d/%m/%Y %H:%i') AS fecha_registro_txt,
           (SELECT u2.nombre FROM usuarios u2 WHERE u2.id = i.propuesta_por) AS propuesta,
           (SELECT COUNT(*) FROM anteproyectos a
             WHERE a.idea_solicitada_id = i.id
               AND (a.estudiante_id = ? OR a.estudiante2_id = ?)) AS es_miembro
    FROM ideas i
    WHERE i.id = ?
    <sql:param value="${sessionScope.usuarioId}" />
    <sql:param value="${sessionScope.usuarioId}" />
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${empty dbError and ver.rowCount == 0}">
  <c:redirect url="ideas.jsp" />
</c:if>
<%-- Una idea POSTULADA solo la ven Coordinacion, el administrador, su autor
     o un miembro del proyecto que la tiene como idea solicitada --%>
<c:if test="${empty dbError and ver.rowCount == 1 and ver.rows[0].estado == 'POSTULADA'
  and sessionScope.rol != 'COORDINACION' and sessionScope.rol != 'ADMINISTRADOR'
  and ver.rows[0].propuesta_por != sessionScope.usuarioId
  and ver.rows[0].es_miembro == 0}">
  <c:redirect url="ideas.jsp" />
</c:if>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<c:url var="urlEditar" value="idea-form.jsp">
  <c:param name="id" value="${ver.rows[0].id}" />
</c:url>

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Detalle de la <span class="badge-lima">IDEA</span></h4>
      <a href="ideas.jsp" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${not empty dbError}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <c:if test="${not empty dbError or ver.rowCount == 0}">
      <p class="text-muted">No se pudo cargar la idea.</p>
    </c:if>
    <c:if test="${empty dbError and ver.rowCount == 1}">
      <dl class="row mb-0">
        <dt class="col-sm-3">T&iacute;tulo</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].titulo}" /></dd>
        <dt class="col-sm-3">Descripci&oacute;n</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].descripcion}" /></dd>
        <dt class="col-sm-3">&Aacute;rea</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].area}" default="&#8212;" /></dd>
        <dt class="col-sm-3">Estado</dt>
        <dd class="col-sm-9">
          <c:if test="${ver.rows[0].estado == 'DISPONIBLE'}">
            <span class="badge text-bg-success">DISPONIBLE</span>
          </c:if>
          <c:if test="${ver.rows[0].estado != 'DISPONIBLE'}">
            <span class="badge text-bg-secondary"><c:out value="${ver.rows[0].estado}" /></span>
          </c:if>
        </dd>
        <dt class="col-sm-3">Propuesta por</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].propuesta}" default="&#8212;" /></dd>
        <dt class="col-sm-3">Fecha de registro</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].fecha_registro_txt}" /></dd>
      </dl>
      <div class="mt-3 d-flex gap-2 flex-wrap">
        <c:if test="${sessionScope.rol == 'COORDINACION'}">
          <a href="${urlEditar}" class="btn btn-lima"><i class="fa-solid fa-pen"></i> Editar</a>
        </c:if>
        <a href="ideas.jsp" class="btn btn-outline-secondary">Volver</a>
      </div>
    </c:if>
  </div>
</div>

<c:import url="includes/footer.jsp" />
