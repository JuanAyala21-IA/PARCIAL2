<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  fase-enviar.jsp (solo ESTUDIANTE, solo POST, sin HTML)
  Fase '1' -> estado 'COORDINACION'.
  Fases '2'/'4' con estado 'ESTUDIANTE' -> estado 'DIRECTOR'
  (requieren director asignado). La fase no cambia.
  Revalida miembro del equipo (estudiante o companero), fase/estado vigentes
  y al menos una entrega de algun miembro en la fase (enviado_por IN
  (estudiante_id, estudiante2_id)).
  Exito -> seguimiento.jsp?id=X&ok=1&dest=... Fallo -> ?error=invalido.
--%>
<c:set var="rolesPermitidos" value="ESTUDIANTE" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:if test="${empty param.fase or (param.fase != '1' and param.fase != '2' and param.fase != '4')}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>

<c:catch var="verError">
  <sql:query var="p" dataSource="${db}">
    SELECT id, estudiante_id, estudiante2_id, director_id, fase, estado FROM anteproyectos WHERE id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${not empty verError or p.rowCount == 0}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:if test="${(p.rows[0].estudiante_id != sessionScope.usuarioId and p.rows[0].estudiante2_id != sessionScope.usuarioId) or p.rows[0].fase != param.fase or p.rows[0].estado != 'ESTUDIANTE'}">
  <c:redirect url="seguimiento.jsp?id=${param.id}&amp;error=invalido" />
</c:if>
<c:if test="${(param.fase == '2' or param.fase == '4') and empty p.rows[0].director_id}">
  <c:redirect url="seguimiento.jsp?id=${param.id}&amp;error=invalido" />
</c:if>

<c:catch var="contError">
  <sql:query var="c1" dataSource="${db}">
    SELECT COUNT(*) AS n FROM entregas WHERE anteproyecto_id = ? AND fase = ? AND enviado_por IN (?, ?)
    <sql:param value="${param.id}" />
    <sql:param value="${param.fase}" />
    <sql:param value="${p.rows[0].estudiante_id}" />
    <sql:param value="${p.rows[0].estudiante2_id}" />
  </sql:query>
</c:catch>
<c:if test="${not empty contError or c1.rows[0].n == 0}">
  <c:redirect url="seguimiento.jsp?id=${param.id}&amp;error=invalido" />
</c:if>
<c:if test="${param.fase == '1'}">
  <c:catch var="solError">
    <sql:query var="sol" dataSource="${db}">
      SELECT a.idea_solicitada_id,
             (SELECT i2.estado FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_estado,
             (SELECT i2.propuesta_por FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_por
      FROM anteproyectos a
      WHERE a.id = ?
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${not empty solError or empty sol.rows[0].idea_solicitada_id
      or (sol.rows[0].sol_estado != 'DISPONIBLE'
          and not (sol.rows[0].sol_estado == 'POSTULADA'
                   and (sol.rows[0].sol_por == p.rows[0].estudiante_id or sol.rows[0].sol_por == p.rows[0].estudiante2_id)))}">
    <c:redirect url="seguimiento.jsp?id=${param.id}&amp;error=invalido" />
  </c:if>
</c:if>

<c:set var="nuevoEstado" value="COORDINACION" />
<c:set var="dest" value="coordinacion" />
<c:if test="${param.fase == '2' or param.fase == '4'}">
  <c:set var="nuevoEstado" value="DIRECTOR" />
  <c:set var="dest" value="director" />
</c:if>

<c:catch var="updError">
  <sql:update var="u" dataSource="${db}">
    UPDATE anteproyectos SET estado = ?, obs_coordinacion = NULL
    WHERE id = ? AND fase = ? AND estado = 'ESTUDIANTE' AND (estudiante_id = ? OR estudiante2_id = ?)
    <sql:param value="${nuevoEstado}" />
    <sql:param value="${param.id}" />
    <sql:param value="${param.fase}" />
    <sql:param value="${sessionScope.usuarioId}" />
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:update>
</c:catch>
<c:choose>
  <c:when test="${empty updError and u > 0}">
    <c:redirect url="seguimiento.jsp?id=${param.id}&amp;ok=1&amp;dest=${dest}" />
  </c:when>
  <c:otherwise>
    <c:redirect url="seguimiento.jsp?id=${param.id}&amp;error=invalido" />
  </c:otherwise>
</c:choose>
