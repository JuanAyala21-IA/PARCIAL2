<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  proyecto-finalizar.jsp (solo COORDINACION/ADMINISTRADOR, solo POST, sin HTML)
  Marca el proyecto en FINALIZADO. Revalida fase 'FINAL',
  estado 'COORDINACION' y fecha/nota no nulas.
  Exito -> sustentacion.jsp?id=X&ok=3. Fallo -> ?error=invalido.
  GET o id inexistente -> mis-proyectos.jsp.
--%>
<c:set var="rolesPermitidos" value="COORDINACION,ADMINISTRADOR" scope="request" />

<jsp:directive.include file="includes/guard.jspf" />
<c:import url="includes/conexion.jsp" />

<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>

<c:catch var="verError">
  <sql:query var="p" dataSource="${db}">
    SELECT id, fase, estado, fecha_sustentacion, nota_sustentacion
    FROM anteproyectos WHERE id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${not empty verError or p.rowCount == 0}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:if test="${p.rows[0].fase != 'FINAL' or p.rows[0].estado != 'COORDINACION' or empty p.rows[0].fecha_sustentacion or empty p.rows[0].nota_sustentacion}">
  <c:redirect url="sustentacion.jsp?id=${param.id}&amp;error=invalido" />
</c:if>

<c:catch var="updError">
  <sql:update var="u" dataSource="${db}">
    UPDATE anteproyectos SET estado = 'FINALIZADO'
    WHERE id = ? AND fase = 'FINAL' AND estado = 'COORDINACION'
      AND fecha_sustentacion IS NOT NULL AND nota_sustentacion IS NOT NULL
    <sql:param value="${param.id}" />
  </sql:update>
</c:catch>
<c:choose>
  <c:when test="${empty updError and u > 0}">
    <c:redirect url="sustentacion.jsp?id=${param.id}&amp;ok=3" />
  </c:when>
  <c:otherwise>
    <c:redirect url="sustentacion.jsp?id=${param.id}&amp;error=invalido" />
  </c:otherwise>
</c:choose>
