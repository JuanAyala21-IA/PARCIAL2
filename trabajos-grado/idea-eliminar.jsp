<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  idea-eliminar.jsp (solo COORDINACION, solo POST, sin HTML)
  Sin POST o sin id -> ideas.jsp. Id inexistente -> ideas.jsp.
  Si la idea no esta DISPONIBLE -> ?error=asignada.
  Si esta solicitada por algun anteproyecto -> ?error=solicitada.
  Si no -> DELETE y ideas.jsp?ok=3.
--%>
<c:set var="rolesPermitidos" value="COORDINACION" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
  <c:redirect url="ideas.jsp" />
</c:if>

<c:catch var="verError">
  <sql:query var="e" dataSource="${db}">
    SELECT id, estado FROM ideas WHERE id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${not empty verError or e.rowCount == 0}">
  <c:redirect url="ideas.jsp" />
</c:if>
<%-- Las ideas POSTULADA por estudiantes no se eliminan desde el banco --%>
<c:if test="${e.rows[0].estado == 'POSTULADA'}">
  <c:redirect url="ideas.jsp?error=postulada" />
</c:if>
<c:if test="${e.rows[0].estado != 'DISPONIBLE'}">
  <c:redirect url="ideas.jsp?error=asignada" />
</c:if>

<c:catch var="solError">
  <sql:query var="sol" dataSource="${db}">
    SELECT COUNT(*) AS n FROM anteproyectos WHERE idea_solicitada_id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${empty solError and sol.rows[0].n > 0}">
  <c:redirect url="ideas.jsp?error=solicitada" />
</c:if>

<c:catch var="delError">
  <sql:update var="d" dataSource="${db}">
    DELETE FROM ideas WHERE id = ?
    <sql:param value="${param.id}" />
  </sql:update>
</c:catch>
<c:choose>
  <c:when test="${empty delError}">
    <c:redirect url="ideas.jsp?ok=3" />
  </c:when>
  <c:otherwise>
    <c:redirect url="ideas.jsp?error=asignada" />
  </c:otherwise>
</c:choose>
