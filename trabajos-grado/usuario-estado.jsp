<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  usuario-estado.jsp (solo ADMINISTRADOR, solo POST, sin HTML)
  accion=inactivar|activar -> UPDATE usuarios SET estado (sql:param).
  - No permite inactivar al propio administrador -> usuarios.jsp?error=propio.
  - No permite inactivar al unico ADMINISTRADOR activo -> usuarios.jsp?error=ultimo-admin.
  - Exito -> usuarios.jsp?ok=12
--%>
<c:set var="rolesPermitidos" value="ADMINISTRADOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
  <c:redirect url="usuarios.jsp" />
</c:if>
<c:if test="${param.accion != 'inactivar' and param.accion != 'activar'}">
  <c:redirect url="usuarios.jsp" />
</c:if>

<%-- Usuario destino --%>
<c:catch var="usrError">
  <sql:query var="usr" dataSource="${db}">
    SELECT u.id, u.estado,
           (SELECT r.nombre FROM roles r WHERE r.id = u.rol_id) AS rol
    FROM usuarios u
    WHERE u.id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${not empty usrError}">
  <c:redirect url="usuarios.jsp" />
</c:if>
<c:if test="${usr.rowCount == 0}">
  <c:redirect url="usuarios.jsp" />
</c:if>

<c:if test="${param.accion == 'inactivar'}">
  <c:if test="${param.id == sessionScope.usuarioId}">
    <c:redirect url="usuarios.jsp?error=propio" />
  </c:if>
  <%-- No dejar el sistema sin administrador activo --%>
  <c:if test="${usr.rows[0].rol == 'ADMINISTRADOR' and usr.rows[0].estado == 'ACTIVO'}">
    <c:catch var="admError">
      <sql:query var="adm" dataSource="${db}">
        SELECT COUNT(*) AS n FROM usuarios u
        JOIN roles r ON r.id = u.rol_id
        WHERE r.nombre = 'ADMINISTRADOR' AND u.estado = 'ACTIVO' AND u.id <> ?
        <sql:param value="${param.id}" />
      </sql:query>
    </c:catch>
    <c:if test="${not empty admError}">
      <c:redirect url="usuarios.jsp" />
    </c:if>
    <c:if test="${adm.rows[0].n == 0}">
      <c:redirect url="usuarios.jsp?error=ultimo-admin" />
    </c:if>
  </c:if>
</c:if>

<c:set var="nuevoEstado" value="${param.accion == 'inactivar' ? 'INACTIVO' : 'ACTIVO'}" />
<c:catch var="upError">
  <sql:update var="up" dataSource="${db}">
    UPDATE usuarios SET estado = ? WHERE id = ?
    <sql:param value="${nuevoEstado}" />
    <sql:param value="${param.id}" />
  </sql:update>
</c:catch>
<c:choose>
  <c:when test="${empty upError}">
    <c:redirect url="usuarios.jsp?ok=12" />
  </c:when>
  <c:otherwise>
    <c:redirect url="usuarios.jsp" />
  </c:otherwise>
</c:choose>
