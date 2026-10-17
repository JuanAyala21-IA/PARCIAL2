<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  usuario-eliminar.jsp (solo ADMINISTRADOR, solo POST, sin HTML)
  Paso 1 del borrado de usuarios.
  1. Sin POST o sin id -> usuarios.jsp.
  2. Es el propio usuario -> usuarios.jsp?error=propio.
  3. Usuario inexistente -> usuarios.jsp.
  4. Unico ADMINISTRADOR activo -> usuarios.jsp?error=ultimo-admin.
  5. Alguna FK hacia usuarios no cubierta por las reglas -> usuario-eliminar-confirmar.jsp
     (nunca se borra a ciegas; la pantalla de confirmacion explica el bloqueo).
  6. Sin ninguna fila relacionada (9 relaciones cubiertas) -> DELETE directo y usuarios.jsp?ok=3.
  7. Con relaciones (o DELETE bloqueado por FK) -> usuario-eliminar-confirmar.jsp?id=X.
--%>
<c:set var="rolesPermitidos" value="ADMINISTRADOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
  <c:redirect url="usuarios.jsp" />
</c:if>
<c:if test="${param.id == sessionScope.usuarioId}">
  <c:redirect url="usuarios.jsp?error=propio" />
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

<%-- FK hacia usuarios que las reglas no cubren: bloqueo preventivo --%>
<c:catch var="esqError">
  <sql:query var="esq" dataSource="${db}">
    SELECT COUNT(*) AS n FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE() AND REFERENCED_TABLE_NAME = 'usuarios'
      AND CONCAT(TABLE_NAME, '.', COLUMN_NAME) NOT IN (
        'anteproyectos.estudiante_id', 'anteproyectos.estudiante2_id',
        'anteproyectos.director_id', 'anteproyectos.evaluador_id',
        'ideas.propuesta_por', 'entregas.enviado_por',
        'revisiones.director_id', 'evaluaciones.evaluador_id',
        'avales.coordinador_id')
  </sql:query>
</c:catch>
<c:if test="${empty esqError and esq.rows[0].n > 0}">
  <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}" />
</c:if>

<%-- Filas relacionadas en las 9 relaciones cubiertas --%>
<c:set var="relTotal" value="${-1}" />
<c:catch var="relError">
  <sql:query var="rel" dataSource="${db}">
    SELECT
      (SELECT COUNT(*) FROM anteproyectos WHERE estudiante_id = ?) AS n_est,
      (SELECT COUNT(*) FROM anteproyectos WHERE estudiante2_id = ?) AS n_est2,
      (SELECT COUNT(*) FROM anteproyectos WHERE director_id = ?) AS n_dir,
      (SELECT COUNT(*) FROM anteproyectos WHERE evaluador_id = ?) AS n_eva,
      (SELECT COUNT(*) FROM ideas WHERE propuesta_por = ?) AS n_ideas,
      (SELECT COUNT(*) FROM entregas WHERE enviado_por = ?) AS n_entregas,
      (SELECT COUNT(*) FROM revisiones WHERE director_id = ?) AS n_rev,
      (SELECT COUNT(*) FROM evaluaciones WHERE evaluador_id = ?) AS n_eval,
      (SELECT COUNT(*) FROM avales WHERE coordinador_id = ?) AS n_ava
    <sql:param value="${param.id}" />
    <sql:param value="${param.id}" />
    <sql:param value="${param.id}" />
    <sql:param value="${param.id}" />
    <sql:param value="${param.id}" />
    <sql:param value="${param.id}" />
    <sql:param value="${param.id}" />
    <sql:param value="${param.id}" />
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${empty relError}">
  <c:set var="relTotal" value="${rel.rows[0].n_est + rel.rows[0].n_est2 + rel.rows[0].n_dir + rel.rows[0].n_eva + rel.rows[0].n_ideas + rel.rows[0].n_entregas + rel.rows[0].n_rev + rel.rows[0].n_eval + rel.rows[0].n_ava}" />
</c:if>

<c:choose>
  <c:when test="${relTotal == 0}">
    <%-- Sin historial: borrado directo --%>
    <c:catch var="delError">
      <sql:update var="d" dataSource="${db}">
        DELETE FROM usuarios WHERE id = ?
        <sql:param value="${param.id}" />
      </sql:update>
    </c:catch>
    <c:choose>
      <c:when test="${empty delError}">
        <c:redirect url="usuarios.jsp?ok=3" />
      </c:when>
      <c:otherwise>
        <%-- Bloqueado por una FK inesperada: la confirmacion explicara el bloqueo --%>
        <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}" />
      </c:otherwise>
    </c:choose>
  </c:when>
  <c:otherwise>
    <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}" />
  </c:otherwise>
</c:choose>
