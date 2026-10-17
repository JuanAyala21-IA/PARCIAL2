<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  avalar.jsp (solo COORDINACION y ADMINISTRADOR)
  Avala la aprobación del evaluador en fase '3' o '5':
  AVALAR -> fase '4' (si '3') con estado 'ESTUDIANTE',
            o fase 'FINAL' (si '5') con estado 'COORDINACION'.
  NO AVALAR -> estado 'EVALUADOR', misma fase, con observaciones.
  Solo aplica si fase es '3'/'5' y estado 'COORDINACION';
  si no -> mis-proyectos.jsp?error=no-aplica.
--%>
<c:set var="titulo" value="Avalar decisión" scope="request" />
<c:set var="activo" value="proyectos" scope="request" />
<c:set var="rolesPermitidos" value="COORDINACION,ADMINISTRADOR" scope="request" />

<jsp:directive.include file="includes/guard.jspf" />
<c:import url="includes/conexion.jsp" />

<c:if test="${empty param.id}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:catch var="dbError">
  <sql:query var="ver" dataSource="${db}">
    SELECT a.id, a.codigo, a.descripcion, a.fase, a.estado,
           (SELECT e2.nombre FROM usuarios e2 WHERE e2.id = a.estudiante_id) AS est_nombre,
           (SELECT e2.nombre FROM usuarios e2 WHERE e2.id = a.estudiante2_id) AS est2_nombre,
           (SELECT e2.codigo FROM usuarios e2 WHERE e2.id = a.estudiante2_id) AS est2_codigo,
           (SELECT d2.nombre FROM usuarios d2 WHERE d2.id = a.director_id) AS dir_nombre,
           (SELECT v2.nombre FROM usuarios v2 WHERE v2.id = a.evaluador_id) AS eva_nombre
    FROM anteproyectos a
    WHERE a.id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${empty dbError and ver.rowCount == 0}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:if test="${empty dbError and ver.rowCount == 1 and (ver.rows[0].estado != 'COORDINACION' or (ver.rows[0].fase != '3' and ver.rows[0].fase != '5'))}">
  <c:redirect url="mis-proyectos.jsp?error=no-aplica" />
</c:if>

<%-- Fase 3 muestra el hilo 2+3; fase 5 el hilo 4+5 --%>
<c:set var="faseEntrega" value="4" />
<c:if test="${ver.rows[0].fase == '3'}">
  <c:set var="faseEntrega" value="2" />
</c:if>
<c:set var="faseActual" value="${ver.rows[0].fase}" />

<c:catch var="dbError2">
  <sql:query var="enlaces" dataSource="${db}">
    SELECT e.fase, e.enlace, e.comentario, e.fecha_envio,
           DATE_FORMAT(e.fecha_envio, '%d/%m/%Y %H:%i') AS fecha_txt,
           (SELECT u2.nombre FROM usuarios u2 WHERE u2.id = e.enviado_por) AS autor,
           CASE WHEN e.enviado_por = a.estudiante_id THEN 'Estudiante'
                WHEN e.enviado_por = a.estudiante2_id THEN 'Estudiante'
                WHEN e.enviado_por = a.director_id THEN 'Director'
                WHEN e.enviado_por = a.evaluador_id THEN 'Evaluador'
                ELSE 'Otro' END AS rol_autor FROM entregas e
    JOIN anteproyectos a ON a.id = e.anteproyecto_id
    WHERE e.anteproyecto_id = ? AND (e.fase = ? OR e.fase = ?)
    ORDER BY e.fecha_envio DESC, e.id DESC
    <sql:param value="${param.id}" />
    <sql:param value="${faseEntrega}" />
    <sql:param value="${faseActual}" />
  </sql:query>
</c:catch>

<c:catch var="dbError3">
  <sql:query var="ultimaDir" dataSource="${db}">
    SELECT decision, observaciones, fecha,
           DATE_FORMAT(fecha, '%d/%m/%Y %H:%i') AS fecha_txt FROM revisiones
    WHERE anteproyecto_id = ? AND fase = ?
    ORDER BY fecha DESC, id DESC LIMIT 1
    <sql:param value="${param.id}" />
    <sql:param value="${faseEntrega}" />
  </sql:query>
</c:catch>

<c:catch var="dbError4">
  <sql:query var="ultimaEva" dataSource="${db}">
    SELECT decision, observaciones, fecha,
           DATE_FORMAT(fecha, '%d/%m/%Y %H:%i') AS fecha_txt FROM evaluaciones
    WHERE anteproyecto_id = ? AND fase = ?
    ORDER BY fecha DESC, id DESC LIMIT 1
    <sql:param value="${param.id}" />
    <sql:param value="${ver.rows[0].fase}" />
  </sql:query>
</c:catch>

<c:if test="${pageContext.request.method == 'POST'}">
  <c:choose>
    <c:when test="${param.decision != 'AVALAR' and param.decision != 'NO_AVALAR'}">
      <c:set var="formError" value="Elija Avalar o No avalar." scope="request" />
    </c:when>
    <c:when test="${param.decision == 'NO_AVALAR' and empty param.observaciones}">
      <c:set var="formError" value="Las observaciones son obligatorias al no avalar." scope="request" />
    </c:when>
    <c:otherwise>
      <c:set var="decisionBD" value="AVALADO" />
      <c:set var="codigoOk" value="13" />
      <c:choose>
        <c:when test="${param.decision == 'AVALAR' and ver.rows[0].fase == '5'}">
          <c:set var="nuevaFase" value="FINAL" />
          <c:set var="nuevoEstado" value="COORDINACION" />
        </c:when>
        <c:when test="${param.decision == 'AVALAR'}">
          <c:set var="nuevaFase" value="4" />
          <c:set var="nuevoEstado" value="ESTUDIANTE" />
        </c:when>
        <c:otherwise>
          <c:set var="decisionBD" value="NO_AVALADO" />
          <c:set var="nuevaFase" value="${ver.rows[0].fase}" />
          <c:set var="nuevoEstado" value="EVALUADOR" />
          <c:set var="codigoOk" value="14" />
        </c:otherwise>
      </c:choose>
      <c:catch var="txError">
        <sql:transaction dataSource="${db}">
          <sql:update var="r">
            INSERT INTO avales (anteproyecto_id, fase, coordinador_id, decision, observaciones)
            VALUES (?, ?, ?, ?, ?)
            <sql:param value="${param.id}" />
            <sql:param value="${ver.rows[0].fase}" />
            <sql:param value="${sessionScope.usuarioId}" />
            <sql:param value="${decisionBD}" />
            <sql:param value="${param.observaciones}" />
          </sql:update>
          <c:choose>
            <c:when test="${param.decision == 'AVALAR'}">
              <sql:update var="u">
                UPDATE anteproyectos SET fase = ?, estado = ?, obs_coordinacion = NULL
                WHERE id = ? AND estado = 'COORDINACION' AND fase = ?
                <sql:param value="${nuevaFase}" />
                <sql:param value="${nuevoEstado}" />
                <sql:param value="${param.id}" />
                <sql:param value="${ver.rows[0].fase}" />
              </sql:update>
            </c:when>
            <c:otherwise>
              <sql:update var="u">
                UPDATE anteproyectos SET fase = ?, estado = ?, obs_coordinacion = ?
                WHERE id = ? AND estado = 'COORDINACION' AND fase = ?
                <sql:param value="${nuevaFase}" />
                <sql:param value="${nuevoEstado}" />
                <sql:param value="${param.observaciones}" />
                <sql:param value="${param.id}" />
                <sql:param value="${ver.rows[0].fase}" />
              </sql:update>
            </c:otherwise>
          </c:choose>
        </sql:transaction>
      </c:catch>
      <c:choose>
        <c:when test="${empty txError and u > 0}">
          <c:redirect url="mis-proyectos.jsp?ok=${codigoOk}" />
        </c:when>
        <c:otherwise>
          <c:set var="formError" value="No se pudo registrar. El proyecto ya cambió de fase o estado." scope="request" />
        </c:otherwise>
      </c:choose>
    </c:otherwise>
  </c:choose>
</c:if>

<c:set var="fObs" value="${param.observaciones}" />

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Avalar <span class="badge-lima">DECISIÓN</span></h4>
      <a href="mis-proyectos.jsp" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${not empty requestScope.formError}">
      <div class="alert alert-danger py-2" role="alert"><c:out value="${requestScope.formError}" /></div>
    </c:if>
    <c:if test="${not empty dbError or not empty dbError2 or not empty dbError3 or not empty dbError4}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <c:if test="${not empty dbError or ver.rowCount == 0}">
      <p class="text-muted">No se pudo cargar el proyecto.</p>
    </c:if>
    <c:if test="${empty dbError and ver.rowCount == 1}">
      <dl class="row mb-0">
        <dt class="col-sm-3">C&oacute;digo</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].codigo}" /></dd>
        <dt class="col-sm-3">Estudiante</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].est_nombre}" default="&#8212;" /></dd>
        <c:if test="${not empty ver.rows[0].est2_nombre}">
          <dt class="col-sm-3">Compañero(a)</dt>
          <dd class="col-sm-9">
            <c:out value="${ver.rows[0].est2_nombre}" />
            <c:if test="${not empty ver.rows[0].est2_codigo}">
              (<c:out value="${ver.rows[0].est2_codigo}" />)
            </c:if>
          </dd>
        </c:if>
        <dt class="col-sm-3">Director</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].dir_nombre}" default="&#8212;" /></dd>
        <dt class="col-sm-3">Evaluador</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].eva_nombre}" default="&#8212;" /></dd>
        <dt class="col-sm-3">Fase</dt>
        <dd class="col-sm-9"><span class="badge-fase">Fase <c:out value="${ver.rows[0].fase}" /></span></dd>
      </dl>

      <h5 class="mt-3">Hilo del documento (fases <c:out value="${faseEntrega}" /> y <c:out value="${faseActual}" />)</h5>
      <c:if test="${empty enlaces.rows}">
        <p class="text-muted">Sin enlaces registrados.</p>
      </c:if>
      <c:forEach var="g" items="${enlaces.rows}">
        <div class="card mb-2">
          <div class="card-body py-2">
            <p class="mb-1">
              <i class="fa-solid fa-link"></i>
              <a href="${fn:escapeXml(g.enlace)}" target="_blank" rel="noopener"><c:out value="${g.enlace}" /></a>
              <span class="badge-fase text-nowrap">Fase <c:out value="${g.fase}" /></span>
            </p>
            <c:if test="${not empty g.comentario}">
              <p class="mb-1"><c:out value="${g.comentario}" /></p>
            </c:if>
            <small class="text-muted">Subido por <c:out value="${g.autor}" default="&#8212;" />
              <span class="badge text-bg-secondary"><c:out value="${g.rol_autor}" /></span>
              el <c:out value="${g.fecha_txt}" /></small>
          </div>
        </div>
      </c:forEach>

      <h5 class="mt-3">&Uacute;ltima decisi&oacute;n del director</h5>
      <c:if test="${empty ultimaDir.rows}">
        <p class="text-muted">Sin revisiones registradas.</p>
      </c:if>
      <c:forEach var="h" items="${ultimaDir.rows}">
        <div class="card mb-2">
          <div class="card-body py-2">
            <p class="mb-1">
              <c:if test="${h.decision == 'APROBADO'}">
                <span class="badge text-bg-success">APROBADO</span>
              </c:if>
              <c:if test="${h.decision != 'APROBADO'}">
                <span class="badge text-bg-warning"><c:out value="${h.decision}" /></span>
              </c:if>
            </p>
            <c:if test="${not empty h.observaciones}">
              <p class="mb-1"><c:out value="${h.observaciones}" /></p>
            </c:if>
            <small class="text-muted"><c:out value="${h.fecha_txt}" /></small>
          </div>
        </div>
      </c:forEach>

      <h5 class="mt-3">&Uacute;ltima decisi&oacute;n del evaluador</h5>
      <c:if test="${empty ultimaEva.rows}">
        <p class="text-muted">Sin evaluaciones registradas.</p>
      </c:if>
      <c:forEach var="v" items="${ultimaEva.rows}">
        <div class="card mb-2">
          <div class="card-body py-2">
            <p class="mb-1">
              <c:if test="${v.decision == 'APROBADO'}">
                <span class="badge text-bg-success">APROBADO</span>
              </c:if>
              <c:if test="${v.decision != 'APROBADO'}">
                <span class="badge text-bg-warning"><c:out value="${v.decision}" /></span>
              </c:if>
            </p>
            <c:if test="${not empty v.observaciones}">
              <p class="mb-1"><c:out value="${v.observaciones}" /></p>
            </c:if>
            <small class="text-muted"><c:out value="${v.fecha_txt}" /></small>
          </div>
        </div>
      </c:forEach>

      <form method="post" action="avalar.jsp" class="mt-3">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
        <div class="row g-3">
          <div class="col-12">
            <label class="form-label" for="observaciones">Observaciones</label>
            <textarea class="form-control" id="observaciones" name="observaciones" rows="2"
                      placeholder="Obligatorias si no avala"><c:out value="${fObs}" /></textarea>
          </div>
        </div>
        <div class="mt-3 d-flex gap-2 flex-wrap">
          <button type="submit" name="decision" value="AVALAR" class="btn btn-lima"><i class="fa-solid fa-check-double"></i> Avalar y continuar</button>
          <button type="submit" name="decision" value="NO_AVALAR" class="btn btn-warning"><i class="fa-solid fa-undo"></i> No avalar y devolver al evaluador</button>
          <a href="mis-proyectos.jsp" class="btn btn-outline-secondary">Cancelar</a>
        </div>
      </form>
    </c:if>
  </div>
</div>

<c:import url="includes/footer.jsp" />
