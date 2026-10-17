<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  evaluar.jsp (solo PROFESOR evaluador del proyecto)
  Evalua la entrega: fase '3' (enlaces de la fase 2) o '5' (enlaces de la 4).
  APROBAR -> misma fase, estado 'COORDINACION' (pendiente de aval).
  DEVOLVER -> fase '2' (si '3') o '4' (si '5'), estado 'ESTUDIANTE'.
  Si no aplica -> mis-proyectos.jsp?error=no-aplica.
--%>
<c:set var="titulo" value="Evaluar proyecto" scope="request" />
<c:set var="activo" value="proyectos" scope="request" />
<c:set var="rolesPermitidos" value="PROFESOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${empty param.id}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:catch var="dbError">
  <sql:query var="ver" dataSource="${db}">
    SELECT a.id, a.codigo, a.descripcion, a.fase, a.estado, a.evaluador_id, a.obs_coordinacion,
           (SELECT e2.nombre FROM usuarios e2 WHERE e2.id = a.estudiante_id) AS est_nombre,
           (SELECT e2.codigo FROM usuarios e2 WHERE e2.id = a.estudiante_id) AS est_codigo,
           (SELECT e2.correo FROM usuarios e2 WHERE e2.id = a.estudiante_id) AS est_correo,
           (SELECT e3.nombre FROM usuarios e3 WHERE e3.id = a.estudiante2_id) AS est2_nombre,
           (SELECT e3.codigo FROM usuarios e3 WHERE e3.id = a.estudiante2_id) AS est2_codigo,
           (SELECT d2.nombre FROM usuarios d2 WHERE d2.id = a.director_id) AS dir_nombre
    FROM anteproyectos a
    WHERE a.id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${empty dbError and ver.rowCount == 0}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:if test="${empty dbError and ver.rowCount == 1 and (ver.rows[0].evaluador_id != sessionScope.usuarioId or ver.rows[0].estado != 'EVALUADOR' or (ver.rows[0].fase != '3' and ver.rows[0].fase != '5'))}">
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
  <sql:query var="ultima" dataSource="${db}">
    SELECT decision, observaciones, fecha,
           DATE_FORMAT(fecha, '%d/%m/%Y %H:%i') AS fecha_txt FROM revisiones
    WHERE anteproyecto_id = ?
    ORDER BY fecha DESC, id DESC LIMIT 1
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>

<c:catch var="dbError4">
  <sql:query var="historial" dataSource="${db}">
    SELECT fase, decision, observaciones, fecha,
           DATE_FORMAT(fecha, '%d/%m/%Y %H:%i') AS fecha_txt FROM evaluaciones
    WHERE anteproyecto_id = ?
    ORDER BY fecha DESC, id DESC
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>

<c:if test="${pageContext.request.method == 'POST'}">
  <c:choose>
    <c:when test="${param.decision != 'APROBAR' and param.decision != 'DEVOLVER'}">
      <c:set var="formError" value="Elija Aprobar o Devolver." scope="request" />
    </c:when>
    <c:when test="${param.decision == 'DEVOLVER' and empty param.observaciones}">
      <c:set var="formError" value="Las observaciones son obligatorias al devolver." scope="request" />
    </c:when>
    <c:otherwise>
      <c:set var="decisionBD" value="APROBADO" />
      <c:set var="codigoOk" value="9" />
      <c:choose>
        <c:when test="${param.decision == 'APROBAR'}">
          <c:set var="nuevaFase" value="${ver.rows[0].fase}" />
          <c:set var="nuevoEstado" value="COORDINACION" />
        </c:when>
        <c:when test="${ver.rows[0].fase == '5'}">
          <c:set var="decisionBD" value="DEVUELTO" />
          <c:set var="nuevaFase" value="4" />
          <c:set var="nuevoEstado" value="ESTUDIANTE" />
          <c:set var="codigoOk" value="10" />
        </c:when>
        <c:otherwise>
          <c:set var="decisionBD" value="DEVUELTO" />
          <c:set var="nuevaFase" value="2" />
          <c:set var="nuevoEstado" value="ESTUDIANTE" />
          <c:set var="codigoOk" value="10" />
        </c:otherwise>
      </c:choose>
      <c:catch var="txError">
        <sql:transaction dataSource="${db}">
          <sql:update var="r">
            INSERT INTO evaluaciones (anteproyecto_id, fase, evaluador_id, observaciones, decision)
            VALUES (?, ?, ?, ?, ?)
            <sql:param value="${param.id}" />
            <sql:param value="${ver.rows[0].fase}" />
            <sql:param value="${sessionScope.usuarioId}" />
            <sql:param value="${param.observaciones}" />
            <sql:param value="${decisionBD}" />
          </sql:update>
          <sql:update var="u">
            UPDATE anteproyectos SET fase = ?, estado = ?, obs_coordinacion = NULL
            WHERE id = ? AND evaluador_id = ? AND estado = 'EVALUADOR' AND fase = ?
            <sql:param value="${nuevaFase}" />
            <sql:param value="${nuevoEstado}" />
            <sql:param value="${param.id}" />
            <sql:param value="${sessionScope.usuarioId}" />
            <sql:param value="${ver.rows[0].fase}" />
          </sql:update>
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
      <h4 class="mb-0">Evaluar <span class="badge-lima">PROYECTO</span></h4>
      <a href="mis-proyectos.jsp" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${not empty requestScope.formError}">
      <div class="alert alert-danger py-2" role="alert"><c:out value="${requestScope.formError}" /></div>
    </c:if>
    <c:if test="${not empty dbError or not empty dbError2 or not empty dbError3 or not empty dbError4}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>
    <c:if test="${not empty ver.rows[0].obs_coordinacion}">
      <div class="alert alert-warning py-2" role="alert">
        Coordinaci&oacute;n no aval&oacute; tu aprobaci&oacute;n anterior.
        <c:out value="${ver.rows[0].obs_coordinacion}" />
      </div>
    </c:if>

    <c:if test="${not empty dbError or ver.rowCount == 0}">
      <p class="text-muted">No se pudo cargar el proyecto.</p>
    </c:if>
    <c:if test="${empty dbError and ver.rowCount == 1}">
      <dl class="row mb-0">
        <dt class="col-sm-3">Estudiante</dt>
        <dd class="col-sm-9">
          <c:out value="${ver.rows[0].est_nombre}" default="&#8212;" />
          <c:if test="${not empty ver.rows[0].est_codigo}">
            (<c:out value="${ver.rows[0].est_codigo}" />)
          </c:if>
          <c:if test="${not empty ver.rows[0].est_correo}">
            &middot; <c:out value="${ver.rows[0].est_correo}" />
          </c:if>
        </dd>
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
        <dt class="col-sm-3">C&oacute;digo</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].codigo}" /></dd>
        <dt class="col-sm-3">Descripci&oacute;n</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].descripcion}" /></dd>
        <dt class="col-sm-3">Fase</dt>
        <dd class="col-sm-9"><span class="badge-fase">Fase <c:out value="${ver.rows[0].fase}" /></span></dd>
      </dl>

      <h5 class="mt-3">Hilo del documento (fases <c:out value="${faseEntrega}" /> y <c:out value="${faseActual}" />)</h5>
      <c:url var="urlSubir" value="entrega.jsp">
        <c:param name="id" value="${ver.rows[0].id}" />
        <c:param name="fase" value="${ver.rows[0].fase}" />
      </c:url>
      <p><a href="${urlSubir}" class="btn btn-sm btn-lima"><i class="fa-solid fa-upload"></i> Subir mi versión (enlace)</a>
        <small class="text-muted">Reemplaza al enlace actual.</small></p>
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

      <h5 class="mt-3">&Uacute;ltima revisi&oacute;n del director</h5>
      <c:if test="${empty ultima.rows}">
        <p class="text-muted">Sin revisiones registradas.</p>
      </c:if>
      <c:forEach var="h" items="${ultima.rows}">
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

      <h5 class="mt-3">Evaluaciones anteriores</h5>
      <c:if test="${empty historial.rows}">
        <p class="text-muted">Sin evaluaciones registradas.</p>
      </c:if>
      <c:forEach var="v" items="${historial.rows}">
        <div class="card mb-2">
          <div class="card-body py-2">
            <p class="mb-1">
              Fase <c:out value="${v.fase}" /> &middot;
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

      <form method="post" action="evaluar.jsp" class="mt-3">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
        <div class="row g-3">
          <div class="col-12">
            <label class="form-label" for="observaciones">Observaciones</label>
            <textarea class="form-control" id="observaciones" name="observaciones" rows="2"
                      placeholder="Obligatorias si devuelve"><c:out value="${fObs}" /></textarea>
          </div>
        </div>
        <div class="mt-3 d-flex gap-2 flex-wrap">
          <button type="submit" name="decision" value="APROBAR" class="btn btn-lima"><i class="fa-solid fa-check"></i> Aprobar y enviar a Coordinación</button>
          <button type="submit" name="decision" value="DEVOLVER" class="btn btn-warning"><i class="fa-solid fa-undo"></i> Devolver al estudiante</button>
          <a href="mis-proyectos.jsp" class="btn btn-outline-secondary">Cancelar</a>
        </div>
        <p class="text-muted mt-2"><small>Tu aprobación pasará a Coordinación para su aval.</small></p>
      </form>
    </c:if>
  </div>
</div>

<c:import url="includes/footer.jsp" />
