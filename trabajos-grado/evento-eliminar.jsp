<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  evento-eliminar.jsp (solo COORDINACION/ADMINISTRADOR, solo POST, sin HTML)
  DELETE y redirige a calendario.jsp?ok=3. Todo dentro de <c:catch>.
--%>
<c:set var="rolesPermitidos" value="COORDINACION,ADMINISTRADOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
  <c:redirect url="calendario.jsp" />
</c:if>

<c:catch var="delError">
  <sql:update var="d" dataSource="${db}">
    DELETE FROM calendario WHERE id = ?
    <sql:param value="${param.id}" />
  </sql:update>
</c:catch>
<c:choose>
  <c:when test="${empty delError}">
    <c:redirect url="calendario.jsp?ok=3" />
  </c:when>
  <c:otherwise>
    <c:redirect url="calendario.jsp" />
  </c:otherwise>
</c:choose>
