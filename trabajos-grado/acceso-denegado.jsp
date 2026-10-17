<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%--
  acceso-denegado.jsp
  Pagina simple con el layout para cuando el rol no tiene permiso.
  Exige sesión (guard sin rolesPermitidos); sin sesión redirige a login.
--%>
<c:set var="titulo" value="Acceso denegado" scope="request" />
<c:set var="activo" value="inicio" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="row justify-content-center">
  <div class="col-md-6">
    <div class="card card-lima shadow-sm text-center">
      <div class="card-body py-4">
        <i class="fa-solid fa-ban fa-2x text-danger"></i>
        <h5 class="mt-2">Acceso denegado</h5>
        <p class="text-muted">Su rol (<strong><c:out value="${sessionScope.rol}" default="sin rol" /></strong>) no tiene permiso para ver esta p&aacute;gina.</p>
        <a href="index.jsp" class="btn btn-lima">Volver al inicio</a>
      </div>
    </div>
  </div>
</div>

<c:import url="includes/footer.jsp" />
