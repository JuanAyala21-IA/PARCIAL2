<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%--
  practicas.jsp (cualquier usuario autenticado)
  "Mis prácticas" no está en el alcance del proyecto: página simple.
--%>
<c:set var="titulo" value="Mis prácticas" scope="request" />
<c:set var="activo" value="practicas" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Mis <span class="badge-lima">PR&Aacute;CTICAS</span></h4>
    </div>
    <hr />
    <div class="alert alert-warning py-2" role="alert">Este m&oacute;dulo no est&aacute; disponible en esta versi&oacute;n del sistema.</div>
    <a href="index.jsp" class="btn btn-lima"><i class="fa-solid fa-house"></i> Volver al inicio</a>
  </div>
</div>

<c:import url="includes/footer.jsp" />
