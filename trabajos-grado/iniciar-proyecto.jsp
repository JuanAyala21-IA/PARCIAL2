<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  iniciar-proyecto.jsp (solo ESTUDIANTE, solo POST, sin HTML)
  Crea el anteproyecto del estudiante en fase '1', estado 'ESTUDIANTE',
  sin director, sin idea asignada ni solicitada.
  Revalida que no es miembro (estudiante o companero) de un proyecto activo.
  Exito -> entrega.jsp?id=X&fase=1&ok=4. Fallo -> ?error=invalido.
--%>
<c:set var="rolesPermitidos" value="ESTUDIANTE" scope="request" />

<jsp:directive.include file="includes/guard.jspf" />
<c:import url="includes/conexion.jsp" />

<c:if test="${pageContext.request.method != 'POST'}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>

<c:catch var="verError">
  <sql:query var="mp" dataSource="${db}">
    SELECT id FROM anteproyectos
    WHERE (estudiante_id = ? OR estudiante2_id = ?) AND estado <> 'RECHAZADO'
    <sql:param value="${sessionScope.usuarioId}" />
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
</c:catch>
<c:if test="${empty verError and mp.rowCount > 0}">
  <c:redirect url="mis-proyectos.jsp?error=tiene-proyecto" />
</c:if>

<c:catch var="txError">
  <sql:transaction dataSource="${db}">
    <sql:update var="a">
      INSERT INTO anteproyectos (codigo, descripcion, estudiante_id, director_id, evaluador_id, idea_id, idea_solicitada_id, fase, estado)
      VALUES ('TMP', 'Propuesta de estudiante para iniciar con proyecto de grado', ?, NULL, NULL, NULL, NULL, '1', 'ESTUDIANTE')
      <sql:param value="${sessionScope.usuarioId}" />
    </sql:update>
    <sql:query var="nuevo">
      SELECT LAST_INSERT_ID() AS id
    </sql:query>
    <sql:update var="b">
      UPDATE anteproyectos SET codigo = CONCAT('GRA-', LPAD(?, 5, '0')) WHERE id = ?
      <sql:param value="${nuevo.rows[0].id}" />
      <sql:param value="${nuevo.rows[0].id}" />
    </sql:update>
  </sql:transaction>
</c:catch>
<c:choose>
  <c:when test="${empty txError}">
    <c:redirect url="entrega.jsp?id=${nuevo.rows[0].id}&fase=1&ok=4" />
  </c:when>
  <c:otherwise>
    <c:redirect url="mis-proyectos.jsp?error=invalido" />
  </c:otherwise>
</c:choose>
