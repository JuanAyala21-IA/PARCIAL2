<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  entrega-eliminar.jsp (solo ESTUDIANTE y PROFESOR, solo POST, sin HTML)
  Revalida por rol: estudiante miembro del equipo con estado 'ESTUDIANTE';
  director con director_id = usuario, fase 2 o 4 y estado 'DIRECTOR';
  evaluador con evaluador_id = usuario, fase 3 o 5 y estado 'EVALUADOR';
  siempre entrega del proyecto y fase vigente, propia (enviado_por = usuario).
  DELETE y redirige a entrega.jsp?id=X&fase=N&ok=3.
  Si falla -> ?error=invalido. Todo dentro de <c:catch>.
--%>
<c:set var="rolesPermitidos" value="ESTUDIANTE,PROFESOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>

<c:catch var="verError">
  <sql:query var="e" dataSource="${db}">
    SELECT id, anteproyecto_id, fase, enviado_por FROM entregas WHERE id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${not empty verError or e.rowCount == 0}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>

<c:catch var="proyError">
  <sql:query var="p" dataSource="${db}">
    SELECT id, estudiante_id, estudiante2_id, director_id, evaluador_id, fase, estado FROM anteproyectos WHERE id = ?
    <sql:param value="${e.rows[0].anteproyecto_id}" />
  </sql:query>
</c:catch>
<c:if test="${not empty proyError or p.rowCount == 0}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:if test="${sessionScope.rol == 'PROFESOR' and p.rows[0].director_id != sessionScope.usuarioId and p.rows[0].evaluador_id != sessionScope.usuarioId}">
  <c:redirect url="acceso-denegado.jsp" />
</c:if>
<c:if test="${sessionScope.rol == 'ESTUDIANTE' and p.rows[0].estudiante_id != sessionScope.usuarioId and p.rows[0].estudiante2_id != sessionScope.usuarioId}">
  <c:redirect url="acceso-denegado.jsp" />
</c:if>
<c:set var="esEst" value="${sessionScope.rol == 'ESTUDIANTE' and (p.rows[0].estudiante_id == sessionScope.usuarioId or p.rows[0].estudiante2_id == sessionScope.usuarioId) and p.rows[0].estado == 'ESTUDIANTE' and (p.rows[0].fase == '1' or p.rows[0].fase == '2' or p.rows[0].fase == '4')}" />
<c:set var="esDir" value="${sessionScope.rol == 'PROFESOR' and p.rows[0].director_id == sessionScope.usuarioId and p.rows[0].estado == 'DIRECTOR' and (p.rows[0].fase == '2' or p.rows[0].fase == '4')}" />
<c:set var="esEva" value="${sessionScope.rol == 'PROFESOR' and p.rows[0].evaluador_id == sessionScope.usuarioId and p.rows[0].estado == 'EVALUADOR' and (p.rows[0].fase == '3' or p.rows[0].fase == '5')}" />
<c:if test="${not (esEst or esDir or esEva) or e.rows[0].fase != p.rows[0].fase or e.rows[0].enviado_por != sessionScope.usuarioId}">
  <c:redirect url="entrega.jsp?id=${e.rows[0].anteproyecto_id}&amp;fase=${e.rows[0].fase}&amp;error=invalido" />
</c:if>

<c:catch var="delError">
  <sql:update var="d" dataSource="${db}">
    DELETE FROM entregas WHERE id = ? AND enviado_por = ?
    <sql:param value="${param.id}" />
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:update>
</c:catch>
<c:choose>
  <c:when test="${empty delError and d > 0}">
    <c:redirect url="entrega.jsp?id=${e.rows[0].anteproyecto_id}&amp;fase=${e.rows[0].fase}&amp;ok=3" />
  </c:when>
  <c:otherwise>
    <c:redirect url="entrega.jsp?id=${e.rows[0].anteproyecto_id}&amp;fase=${e.rows[0].fase}&amp;error=invalido" />
  </c:otherwise>
</c:choose>
