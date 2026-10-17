<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  atender-solicitud.jsp (solo COORDINACION y ADMINISTRADOR)
  Atiende la solicitud de Fase 1 en un solo paso:
  APROBAR asigna idea (la solicitada), director y evaluador,
  descripcion = titulo de la idea, fase = '2', estado = 'ESTUDIANTE'.
  DEVOLVER pone estado = 'ESTUDIANTE' con observaciones (obs_coordinacion).
  Solo aplica si fase = '1', estado = 'COORDINACION' e idea solicitada;
  si no -> mis-proyectos.jsp?error=no-aplica.
--%>
<c:set var="titulo" value="Atender solicitud" scope="request" />
<c:set var="activo" value="proyectos" scope="request" />
<c:set var="rolesPermitidos" value="COORDINACION,ADMINISTRADOR" scope="request" />

<jsp:directive.include file="includes/guard.jspf" />
<c:import url="includes/conexion.jsp" />

<c:if test="${empty param.id}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:catch var="dbError">
  <sql:query var="ver" dataSource="${db}">
    SELECT a.id, a.codigo, a.descripcion, a.fase, a.estado, a.idea_solicitada_id,
           a.estudiante2_id,
           (SELECT e2.nombre FROM usuarios e2 WHERE e2.id = a.estudiante_id) AS est_nombre,
           (SELECT e2.codigo FROM usuarios e2 WHERE e2.id = a.estudiante_id) AS est_codigo,
           (SELECT e3.nombre FROM usuarios e3 WHERE e3.id = a.estudiante2_id) AS est2_nombre,
           (SELECT e3.codigo FROM usuarios e3 WHERE e3.id = a.estudiante2_id) AS est2_codigo,
           (SELECT u5.nombre FROM usuarios u5
             WHERE u5.id = (SELECT i3.propuesta_por FROM ideas i3 WHERE i3.id = a.idea_solicitada_id)) AS sol_por_nombre,
           (SELECT i2.titulo FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_titulo,
           (SELECT i2.area FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_area,
           (SELECT i2.descripcion FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_desc,
           (SELECT i2.estado FROM ideas i2 WHERE i2.id = a.idea_solicitada_id) AS sol_estado
    FROM anteproyectos a
    WHERE a.id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${empty dbError and ver.rowCount == 0}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:if test="${empty dbError and ver.rowCount == 1 and (ver.rows[0].fase != '1' or ver.rows[0].estado != 'COORDINACION' or empty ver.rows[0].idea_solicitada_id)}">
  <c:redirect url="mis-proyectos.jsp?error=no-aplica" />
</c:if>
<c:set var="ideaLibre" value="${ver.rows[0].sol_estado == 'DISPONIBLE'}" />
<c:set var="ideaPostulada" value="${ver.rows[0].sol_estado == 'POSTULADA'}" />

<c:catch var="dbError2">
  <sql:query var="directores" dataSource="${db}">
    SELECT u.id, u.codigo, u.nombre, u.correo FROM usuarios u
    JOIN roles r ON r.id = u.rol_id
    WHERE r.nombre = 'PROFESOR' AND u.estado = 'ACTIVO'
    ORDER BY u.nombre
  </sql:query>
</c:catch>

<c:catch var="dbError3">
  <sql:query var="evaluadores" dataSource="${db}">
    SELECT u.id, u.codigo, u.nombre, u.correo FROM usuarios u
    JOIN roles r ON r.id = u.rol_id
    WHERE r.nombre = 'PROFESOR' AND u.estado = 'ACTIVO'
    ORDER BY u.nombre
  </sql:query>
</c:catch>

<c:catch var="dbError4">
  <sql:query var="pagos" dataSource="${db}">
    SELECT enlace, comentario, fecha_envio,
           DATE_FORMAT(fecha_envio, '%d/%m/%Y %H:%i') AS fecha_txt FROM entregas
    WHERE anteproyecto_id = ? AND fase = '1'
    ORDER BY fecha_envio DESC, id DESC
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>

<c:catch var="dbError5">
  <sql:query var="otras" dataSource="${db}">
    SELECT COUNT(*) AS n FROM anteproyectos
    WHERE idea_solicitada_id = ? AND id <> ?
    <sql:param value="${ver.rows[0].idea_solicitada_id}" />
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
    <c:when test="${param.decision == 'APROBAR' and (empty param.director_id or empty param.evaluador_id)}">
      <c:set var="formError" value="Debe elegir director y evaluador para aprobar." scope="request" />
    </c:when>
    <c:when test="${param.decision == 'APROBAR' and param.director_id == param.evaluador_id}">
      <c:set var="formError" value="El director y el evaluador no pueden ser la misma persona." scope="request" />
    </c:when>
    <c:otherwise>
      <c:catch var="valError">
        <sql:query var="val" dataSource="${db}">
          SELECT (SELECT COUNT(*) FROM usuarios u JOIN roles r ON r.id = u.rol_id
                  WHERE u.id = ? AND r.nombre = 'PROFESOR' AND u.estado = 'ACTIVO') AS dir_ok,
                 (SELECT COUNT(*) FROM usuarios u JOIN roles r ON r.id = u.rol_id
                  WHERE u.id = ? AND r.nombre = 'PROFESOR' AND u.estado = 'ACTIVO') AS eva_ok,
                 (SELECT COUNT(*) FROM anteproyectos a
                  WHERE a.id = ? AND a.fase = '1' AND a.estado = 'COORDINACION'
                    AND a.idea_solicitada_id IS NOT NULL) AS proy_ok
          <sql:param value="${param.director_id}" />
          <sql:param value="${param.evaluador_id}" />
          <sql:param value="${param.id}" />
        </sql:query>
      </c:catch>
      <c:choose>
        <c:when test="${not empty valError or val.rows[0].proy_ok == 0 or (param.decision == 'APROBAR' and (val.rows[0].dir_ok == 0 or val.rows[0].eva_ok == 0))}">
          <c:set var="formError" value="Datos no válidos. Verifique director, evaluador y proyecto." scope="request" />
        </c:when>
        <c:otherwise>
          <c:choose>
            <c:when test="${param.decision == 'APROBAR'}">
              <c:catch var="txError">
                <sql:transaction dataSource="${db}">
                  <sql:update var="m">
                    UPDATE ideas SET estado = 'ASIGNADA'
                    WHERE id = ? AND estado IN ('DISPONIBLE', 'POSTULADA')
                    <sql:param value="${ver.rows[0].idea_solicitada_id}" />
                  </sql:update>
                  <sql:update var="u">
                    UPDATE anteproyectos SET idea_id = idea_solicitada_id, director_id = ?, evaluador_id = ?,
                           descripcion = (SELECT i2.titulo FROM ideas i2 WHERE i2.id = ?),
                           fase = '2', estado = 'ESTUDIANTE', obs_coordinacion = NULL
                    WHERE id = ? AND fase = '1' AND estado = 'COORDINACION' AND idea_solicitada_id IS NOT NULL
                      AND ? <> ?
                    <sql:param value="${param.director_id}" />
                    <sql:param value="${param.evaluador_id}" />
                    <sql:param value="${ver.rows[0].idea_solicitada_id}" />
                    <sql:param value="${param.id}" />
                    <sql:param value="${param.director_id}" />
                    <sql:param value="${param.evaluador_id}" />
                  </sql:update>
                  <sql:update var="o">
                    UPDATE anteproyectos SET idea_solicitada_id = NULL, estado = 'ESTUDIANTE',
                           obs_coordinacion = 'La idea que elegiste ya fue asignada a otro estudiante. Elige otra idea del banco.'
                    WHERE idea_solicitada_id = ? AND id <> ? AND fase = '1' AND estado IN ('ESTUDIANTE', 'COORDINACION')
                    <sql:param value="${ver.rows[0].idea_solicitada_id}" />
                    <sql:param value="${param.id}" />
                  </sql:update>
                </sql:transaction>
              </c:catch>
              <c:choose>
                <c:when test="${empty txError and m > 0 and u > 0}">
                  <c:redirect url="mis-proyectos.jsp?ok=5" />
                </c:when>
                <c:when test="${empty txError}">
                  <c:redirect url="mis-proyectos.jsp?error=idea-no-disponible" />
                </c:when>
                <c:otherwise>
                  <c:set var="formError" value="No se pudo aprobar. Verifique que el director y el evaluador sean personas distintas y que el proyecto siga vigente (posible violación del CHECK)." scope="request" />
                </c:otherwise>
              </c:choose>
            </c:when>
            <c:otherwise>
              <c:catch var="updError">
                <sql:update var="u" dataSource="${db}">
                  UPDATE anteproyectos SET estado = 'ESTUDIANTE', obs_coordinacion = ?
                  WHERE id = ? AND fase = '1' AND estado = 'COORDINACION'
                  <sql:param value="${param.observaciones}" />
                  <sql:param value="${param.id}" />
                </sql:update>
              </c:catch>
              <c:choose>
                <c:when test="${empty updError and u > 0}">
                  <c:redirect url="mis-proyectos.jsp?ok=11" />
                </c:when>
                <c:otherwise>
                  <c:set var="formError" value="No se pudo devolver. El proyecto ya cambió de fase o estado." scope="request" />
                </c:otherwise>
              </c:choose>
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:otherwise>
  </c:choose>
</c:if>

<c:set var="fDir" value="" />
<c:set var="fEva" value="" />
<c:set var="fObs" value="${param.observaciones}" />
<c:if test="${pageContext.request.method == 'POST'}">
  <c:set var="fDir" value="${param.director_id}" />
  <c:set var="fEva" value="${param.evaluador_id}" />
</c:if>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Atender <span class="badge-lima">SOLICITUD</span></h4>
      <a href="mis-proyectos.jsp" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${not empty requestScope.formError}">
      <div class="alert alert-danger py-2" role="alert"><c:out value="${requestScope.formError}" /></div>
    </c:if>
    <c:if test="${not empty dbError or not empty dbError2 or not empty dbError3 or not empty dbError4 or not empty dbError5}">
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
        <dd class="col-sm-9">
          <c:out value="${ver.rows[0].est_nombre}" default="&#8212;" />
          <c:if test="${not empty ver.rows[0].est_codigo}">
            (<c:out value="${ver.rows[0].est_codigo}" />)
          </c:if>
          <c:if test="${not empty ver.rows[0].est2_nombre}">
            <br />
            <span class="badge text-bg-info">Compañero(a)</span>
            <c:out value="${ver.rows[0].est2_nombre}" />
            <c:if test="${not empty ver.rows[0].est2_codigo}">
              (<c:out value="${ver.rows[0].est2_codigo}" />)
            </c:if>
          </c:if>
        </dd>
      </dl>

      <h5 class="mt-3">Comprobante de pago (Fase 1)</h5>
      <c:if test="${empty pagos.rows}">
        <p class="text-muted">Sin enlaces registrados.</p>
      </c:if>
      <c:forEach var="g" items="${pagos.rows}">
        <div class="card mb-2">
          <div class="card-body py-2">
            <p class="mb-1">
              <i class="fa-solid fa-link"></i>
              <a href="${fn:escapeXml(g.enlace)}" target="_blank" rel="noopener"><c:out value="${g.enlace}" /></a>
            </p>
            <c:if test="${not empty g.comentario}">
              <p class="mb-1"><c:out value="${g.comentario}" /></p>
            </c:if>
            <small class="text-muted"><c:out value="${g.fecha_txt}" /></small>
          </div>
        </div>
      </c:forEach>

      <h5 class="mt-3">Idea solicitada</h5>
      <dl class="row mb-0">
        <dt class="col-sm-3">T&iacute;tulo</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].sol_titulo}" default="&#8212;" />
          <c:if test="${ideaPostulada}">
            <span class="badge text-bg-info">Propuesta por el estudiante</span>
            <small class="text-muted"><c:out value="${ver.rows[0].sol_por_nombre}" default="&#8212;" /></small>
          </c:if>
        </dd>
        <dt class="col-sm-3">&Aacute;rea</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].sol_area}" default="&#8212;" /></dd>
        <dt class="col-sm-3">Descripci&oacute;n</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].sol_desc}" default="&#8212;" /></dd>
        <dt class="col-sm-3">Estado</dt>
        <dd class="col-sm-9"><span class="badge text-bg-secondary"><c:out value="${ver.rows[0].sol_estado}" /></span></dd>
      </dl>
      <c:if test="${not ideaLibre and not ideaPostulada}">
        <div class="alert alert-danger py-2 mt-2" role="alert">Esta idea ya fue asignada a otro proyecto.</div>
      </c:if>
      <c:if test="${otras.rows[0].n > 0 and not ideaPostulada}">
        <div class="alert alert-warning py-2 mt-2" role="alert"><c:out value="${otras.rows[0].n}" /> proyecto(s) también solicita(n) esta misma idea.</div>
      </c:if>

      <form method="post" action="atender-solicitud.jsp" class="mt-3">
        <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
        <c:if test="${empty dbError2 and directores.rowCount < 2}">
          <div class="alert alert-warning py-2" role="alert">Se necesitan al menos dos profesores activos para asignar director y evaluador distintos.</div>
        </c:if>
        <div class="row g-3">
          <div class="col-md-6">
            <label class="form-label" for="director_id">Director</label>
            <c:choose>
              <c:when test="${empty directores.rows}">
                <div class="alert alert-warning py-2" role="alert">No hay directores activos registrados.</div>
              </c:when>
              <c:otherwise>
                <select class="form-select" id="director_id" name="director_id">
                  <option value="">Seleccione un director</option>
                  <c:forEach var="d" items="${directores.rows}">
                    <option value="${d.id}" ${fDir == d.id ? 'selected' : ''}><c:out value="${d.nombre}" /> (<c:out value="${d.codigo}" default="${d.correo}" />)</option>
                  </c:forEach>
                </select>
              </c:otherwise>
            </c:choose>
          </div>
          <div class="col-md-6">
            <label class="form-label" for="evaluador_id">Evaluador</label>
            <c:choose>
              <c:when test="${empty evaluadores.rows}">
                <div class="alert alert-warning py-2" role="alert">No hay evaluadores activos registrados.</div>
              </c:when>
              <c:otherwise>
                <select class="form-select" id="evaluador_id" name="evaluador_id">
                  <option value="">Seleccione un evaluador</option>
                  <c:forEach var="v" items="${evaluadores.rows}">
                    <option value="${v.id}" ${fEva == v.id ? 'selected' : ''}><c:out value="${v.nombre}" /> (<c:out value="${v.codigo}" default="${v.correo}" />)</option>
                  </c:forEach>
                </select>
              </c:otherwise>
            </c:choose>
          </div>
          <div class="col-12">
            <label class="form-label" for="observaciones">Observaciones</label>
            <textarea class="form-control" id="observaciones" name="observaciones" rows="2"
                      placeholder="Obligatorias si devuelve"><c:out value="${fObs}" /></textarea>
            <small class="text-muted">Un profesor puede ser director en unos proyectos y evaluador en otros, pero no en el mismo.</small>
          </div>
        </div>
        <div class="mt-3 d-flex gap-2 flex-wrap">
          <c:if test="${ideaLibre or ideaPostulada}">
            <button type="submit" name="decision" value="APROBAR" class="btn btn-lima"><i class="fa-solid fa-check-double"></i> Aprobar y asignar</button>
          </c:if>
          <button type="submit" name="decision" value="DEVOLVER" class="btn btn-warning"><i class="fa-solid fa-undo"></i> Devolver al estudiante</button>
          <a href="mis-proyectos.jsp" class="btn btn-outline-secondary">Cancelar</a>
        </div>
      </form>
    </c:if>
  </div>
</div>

<c:import url="includes/footer.jsp" />
