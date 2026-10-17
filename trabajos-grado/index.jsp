<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%--
  index.jsp (pagina protegida)
  Requiere sesion via guard.jspf. Sin rolesPermitidos: basta estar autenticado.
--%>
<c:set var="titulo" value="Inicio" scope="request" />
<c:set var="activo" value="inicio" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />
<c:import url="includes/conexion.jsp" />

<c:if test="${sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR'}">
  <c:catch var="dbErrPen">
    <sql:query var="pen" dataSource="${db}">
      SELECT COUNT(*) AS n FROM anteproyectos WHERE fase = '1' AND estado = 'COORDINACION'
    </sql:query>
  </c:catch>
  <c:catch var="dbErrAva">
    <sql:query var="ava" dataSource="${db}">
      SELECT COUNT(*) AS n FROM anteproyectos WHERE estado = 'COORDINACION' AND (fase = '3' OR fase = '5')
    </sql:query>
  </c:catch>
</c:if>

<div class="row g-3">
  <div class="col-md-8">
    <div class="card card-lima shadow-sm">
      <div class="card-body">
        <h5 class="card-title">Hola, <c:out value="${sessionScope.usuarioNombre}" />.</h5>
        <c:choose>
          <c:when test="${sessionScope.rol == 'ADMINISTRADOR'}">
            <p class="card-text text-muted">Administre usuarios, calendario institucional y documentos del sistema.</p>
          </c:when>
          <c:when test="${sessionScope.rol == 'COORDINACION'}">
            <p class="card-text text-muted">Gestione anteproyectos, evaluadores y el cronograma institucional.</p>
          </c:when>
          <c:when test="${sessionScope.rol == 'PROFESOR'}">
            <p class="card-text text-muted">Aquí verás los proyectos donde eres director o evaluador.</p>
          </c:when>
          <c:when test="${sessionScope.rol == 'ESTUDIANTE'}">
            <p class="card-text text-muted">Explore el banco de ideas y haga seguimiento a su proyecto y pr&aacute;cticas.</p>
          </c:when>
          <c:otherwise>
            <p class="card-text text-muted">Bienvenido al Sistema de Trabajos de Grado.</p>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </div>
  <div class="col-md-4">
    <div class="card card-lima shadow-sm">
      <div class="card-body">
        <h6 class="card-title"><i class="fa-solid fa-user-gear"></i> Sesi&oacute;n actual</h6>
        <p class="mb-1">Usuario: <strong><c:out value="${sessionScope.usuarioNombre}" /></strong></p>
        <p class="mb-1">Rol: <strong><c:out value="${sessionScope.rol}" /></strong></p>
        <a href="logout.jsp" class="btn btn-sm btn-outline-secondary mt-2">
          <i class="fa-solid fa-right-from-bracket"></i> Cerrar sesi&oacute;n
        </a>
      </div>
    </div>
  </div>
</div>

<c:if test="${sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR'}">
  <div class="row g-3 mt-1">
    <div class="col-md-6">
      <div class="card card-lima shadow-sm">
        <div class="card-body">
          <c:choose>
            <c:when test="${pen.rows[0].n > 0}">
              <h5 class="card-title">Solicitudes pendientes: <c:out value="${pen.rows[0].n}" /></h5>
              <a href="mis-proyectos.jsp?pendientes=1" class="btn btn-lima mt-2">Ver solicitudes</a>
            </c:when>
            <c:otherwise>
              <p class="card-text text-muted mb-0">No hay solicitudes pendientes.</p>
            </c:otherwise>
          </c:choose>
        </div>
      </div>
    </div>
    <div class="col-md-6">
      <div class="card card-lima shadow-sm">
        <div class="card-body">
          <c:choose>
            <c:when test="${ava.rows[0].n > 0}">
              <h5 class="card-title">Avales pendientes: <c:out value="${ava.rows[0].n}" /></h5>
              <a href="mis-proyectos.jsp?avales=1" class="btn btn-lima mt-2">Ver avales</a>
            </c:when>
            <c:otherwise>
              <p class="card-text text-muted mb-0">No hay avales pendientes.</p>
            </c:otherwise>
          </c:choose>
        </div>
      </div>
    </div>
  </div>
</c:if>

<c:import url="includes/footer.jsp" />
