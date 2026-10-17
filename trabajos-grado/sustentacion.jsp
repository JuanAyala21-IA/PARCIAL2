<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  sustentacion.jsp (todos los autenticados, con alcance por rol)
  Solo aplica a proyectos en fase 'FINAL'; si no, redirige a seguimiento.
  Ajeno -> acceso-denegado.jsp. Inexistente -> mis-proyectos.jsp.
  Gestión (fecha, nota, finalizar) solo COORDINACION/ADMINISTRADOR
  con estado 'COORDINACION'; con 'FINALIZADO' todo es de lectura.
--%>
<c:set var="titulo" value="Sustentación del proyecto" scope="request" />
<c:set var="activo" value="proyectos" scope="request" />

<jsp:directive.include file="includes/guard.jspf" />
<c:import url="includes/conexion.jsp" />

<c:if test="${empty param.id}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:catch var="dbError">
  <sql:query var="ver" dataSource="${db}">
    SELECT a.id, a.codigo, a.descripcion, a.fase, a.estado,
           a.estudiante_id, a.director_id, a.evaluador_id,
           a.fecha_sustentacion,
           DATE_FORMAT(a.fecha_sustentacion, '%d/%m/%Y') AS fecha_txt,
           DATE_FORMAT(a.fecha_sustentacion, '%Y-%m-%d') AS fecha_iso,
           a.nota_sustentacion,
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

<%-- Control de alcance por rol (igual que proyecto-ver.jsp) --%>
<c:set var="autorizado" value="false" />
<c:if test="${sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR'}">
  <c:set var="autorizado" value="true" />
</c:if>
<c:if test="${sessionScope.rol == 'ESTUDIANTE' and (ver.rows[0].estudiante_id == sessionScope.usuarioId or ver.rows[0].estudiante2_id == sessionScope.usuarioId)}">
  <c:set var="autorizado" value="true" />
</c:if>
<c:if test="${sessionScope.rol == 'PROFESOR' and (ver.rows[0].director_id == sessionScope.usuarioId or ver.rows[0].evaluador_id == sessionScope.usuarioId)}">
  <c:set var="autorizado" value="true" />
</c:if>
<c:if test="${empty dbError and ver.rowCount == 1 and not autorizado}">
  <c:redirect url="acceso-denegado.jsp" />
</c:if>
<c:if test="${empty dbError and ver.rowCount == 1 and ver.rows[0].fase != 'FINAL'}">
  <c:redirect url="seguimiento.jsp?id=${param.id}" />
</c:if>

<c:set var="puedeGestionar" value="${(sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR') and ver.rows[0].estado == 'COORDINACION'}" />
<c:set var="tieneFecha" value="${not empty ver.rows[0].fecha_sustentacion}" />
<c:set var="tieneNota" value="${not empty ver.rows[0].nota_sustentacion}" />

<c:if test="${pageContext.request.method == 'POST'}">
  <c:choose>
    <c:when test="${not puedeGestionar}">
      <c:set var="formError" value="No tiene permiso para gestionar la sustentación." scope="request" />
    </c:when>
    <c:when test="${param.accion == 'fecha'}">
      <c:choose>
        <c:when test="${empty param.fecha}">
          <c:set var="formError" value="La fecha es obligatoria." scope="request" />
        </c:when>
        <c:when test="${fn:length(param.fecha) != 10 or fn:substring(param.fecha, 4, 5) != '-' or fn:substring(param.fecha, 7, 8) != '-'}">
          <c:set var="formError" value="La fecha debe tener formato aaaa-mm-dd." scope="request" />
        </c:when>
        <c:otherwise>
          <c:catch var="saveError">
            <sql:update var="n" dataSource="${db}">
              UPDATE anteproyectos SET fecha_sustentacion = ?
              WHERE id = ? AND fase = 'FINAL' AND estado = 'COORDINACION'
              <sql:param value="${param.fecha}" />
              <sql:param value="${param.id}" />
            </sql:update>
          </c:catch>
          <c:choose>
            <c:when test="${empty saveError and n > 0}">
              <c:redirect url="sustentacion.jsp?id=${param.id}&ok=1" />
            </c:when>
            <c:otherwise>
              <c:set var="formError" value="No se pudo guardar la fecha. Verifique los datos." scope="request" />
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:when>
    <c:when test="${param.accion == 'nota'}">
      <c:set var="notaTxt" value="${fn:replace(param.nota, ',', '.')}" />
      <c:catch var="numError">
        <fmt:parseNumber var="nota" value="${notaTxt}" />
      </c:catch>
      <c:choose>
        <c:when test="${empty param.nota}">
          <c:set var="formError" value="La nota es obligatoria." scope="request" />
        </c:when>
        <c:when test="${not empty numError or nota < 0 or nota > 5}">
          <c:set var="formError" value="La nota debe estar entre 0.0 y 5.0." scope="request" />
        </c:when>
        <c:otherwise>
          <c:catch var="saveError">
            <sql:update var="n" dataSource="${db}">
              UPDATE anteproyectos SET nota_sustentacion = ?
              WHERE id = ? AND fase = 'FINAL' AND estado = 'COORDINACION'
              <sql:param value="${nota}" />
              <sql:param value="${param.id}" />
            </sql:update>
          </c:catch>
          <c:choose>
            <c:when test="${empty saveError and n > 0}">
              <c:redirect url="sustentacion.jsp?id=${param.id}&ok=2" />
            </c:when>
            <c:otherwise>
              <c:set var="formError" value="No se pudo guardar la nota. Verifique los datos." scope="request" />
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </c:when>
    <c:otherwise>
      <c:set var="formError" value="Acción no válida." scope="request" />
    </c:otherwise>
  </c:choose>
</c:if>

<c:set var="fFecha" value="${ver.rows[0].fecha_iso}" />
<c:set var="fNota" value="" />
<c:if test="${pageContext.request.method == 'POST'}">
  <c:set var="fFecha" value="${param.fecha}" />
  <c:set var="fNota" value="${param.nota}" />
</c:if>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<c:url var="urlVolver" value="seguimiento.jsp">
  <c:param name="id" value="${param.id}" />
</c:url>

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Sustentación del <span class="badge-lima">PROYECTO</span></h4>
      <a href="${urlVolver}" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${param.ok == 1}">
      <div class="alert alert-success py-2" role="alert">Fecha de sustentación guardada.</div>
    </c:if>
    <c:if test="${param.ok == 2}">
      <div class="alert alert-success py-2" role="alert">Nota de sustentación guardada.</div>
    </c:if>
    <c:if test="${param.ok == 3}">
      <div class="alert alert-success py-2" role="alert">Proyecto finalizado.</div>
    </c:if>
    <c:if test="${param.error == 'invalido'}">
      <div class="alert alert-danger py-2" role="alert">No se pudo procesar la solicitud. Verifique los datos.</div>
    </c:if>
    <c:if test="${ver.rows[0].estado == 'FINALIZADO'}">
      <div class="alert alert-success py-2" role="alert">Proyecto finalizado.</div>
    </c:if>
    <c:if test="${not empty requestScope.formError}">
      <div class="alert alert-danger py-2" role="alert"><c:out value="${requestScope.formError}" /></div>
    </c:if>
    <c:if test="${not empty dbError}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <c:if test="${not empty dbError or ver.rowCount == 0}">
      <p class="text-muted">No se pudo cargar el proyecto.</p>
    </c:if>
    <c:if test="${empty dbError and ver.rowCount == 1}">
      <dl class="row mb-0">
        <dt class="col-sm-3">C&oacute;digo</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].codigo}" /></dd>
        <dt class="col-sm-3">Descripci&oacute;n</dt>
        <dd class="col-sm-9"><c:out value="${ver.rows[0].descripcion}" /></dd>
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
      </dl>

      <h5 class="mt-3">1. Fecha de sustentación</h5>
      <c:choose>
        <c:when test="${tieneFecha}">
          <p><strong><c:out value="${ver.rows[0].fecha_txt}" /></strong></p>
        </c:when>
        <c:otherwise>
          <p class="text-muted">Aún no programada.</p>
        </c:otherwise>
      </c:choose>
      <c:if test="${puedeGestionar}">
        <form method="post" action="sustentacion.jsp" class="mb-3">
          <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
          <input type="hidden" name="accion" value="fecha" />
          <div class="row g-3">
            <div class="col-md-4">
              <label class="form-label" for="fecha">Fecha</label>
              <input type="date" class="form-control" id="fecha" name="fecha" required="required"
                     value="${fn:escapeXml(fFecha)}" />
            </div>
          </div>
          <div class="mt-3">
            <button type="submit" class="btn btn-lima"><i class="fa-solid fa-floppy-disk"></i> Guardar fecha</button>
          </div>
        </form>
      </c:if>

      <h5 class="mt-3">2. Nota de la sustentación</h5>
      <c:choose>
        <c:when test="${tieneNota}">
          <p class="mb-1"><strong><c:out value="${ver.rows[0].nota_sustentacion}" /></strong>
            <c:if test="${ver.rows[0].nota_sustentacion >= 3.0}">
              <span class="badge text-bg-success">Aprobada</span>
            </c:if>
            <c:if test="${ver.rows[0].nota_sustentacion < 3.0}">
              <span class="badge text-bg-danger">Reprobada</span>
            </c:if>
          </p>
        </c:when>
        <c:otherwise>
          <p class="text-muted">Aún sin nota.</p>
        </c:otherwise>
      </c:choose>
      <c:if test="${puedeGestionar}">
        <c:choose>
          <c:when test="${tieneFecha}">
            <form method="post" action="sustentacion.jsp" class="mb-3">
              <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
              <input type="hidden" name="accion" value="nota" />
              <div class="row g-3">
                <div class="col-md-4">
                  <label class="form-label" for="nota">Nota (0.0 a 5.0)</label>
                  <input type="number" class="form-control" id="nota" name="nota"
                         min="0" max="5" step="0.1" required="required" value="${fn:escapeXml(fNota)}" />
                </div>
              </div>
              <div class="mt-3">
                <button type="submit" class="btn btn-lima"><i class="fa-solid fa-floppy-disk"></i> Guardar nota</button>
              </div>
            </form>
          </c:when>
          <c:otherwise>
            <div class="alert alert-warning py-2" role="alert">Registra primero la fecha de sustentación.</div>
          </c:otherwise>
        </c:choose>
      </c:if>

      <h5 class="mt-3">3. Estado del proyecto</h5>
      <p>
        <c:if test="${ver.rows[0].estado == 'FINALIZADO'}">
          <span class="badge text-bg-success">FINALIZADO</span>
        </c:if>
        <c:if test="${ver.rows[0].estado != 'FINALIZADO'}">
          <span class="badge text-bg-warning">En sustentación</span>
        </c:if>
      </p>
      <c:if test="${puedeGestionar}">
        <c:choose>
          <c:when test="${tieneFecha and tieneNota}">
            <button type="button" class="btn btn-dark" data-bs-toggle="modal" data-bs-target="#modalFinalizar"><i class="fa-solid fa-flag-checkered"></i> Marcar como finalizado</button>
            <div class="modal fade" id="modalFinalizar" tabindex="-1" aria-hidden="true">
              <div class="modal-dialog">
                <div class="modal-content">
                  <div class="modal-header">
                    <h5 class="modal-title">Confirmar finalización</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                  </div>
                  <div class="modal-body">
                    Al finalizar no podrás modificar la fecha ni la nota. &iquest;Continuar?
                  </div>
                  <div class="modal-footer">
                    <form method="post" action="proyecto-finalizar.jsp">
                      <input type="hidden" name="id" value="${fn:escapeXml(param.id)}" />
                      <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                      <button type="submit" class="btn btn-dark">Confirmar</button>
                    </form>
                  </div>
                </div>
              </div>
            </div>
          </c:when>
          <c:otherwise>
            <button type="button" class="btn btn-dark" disabled="disabled"><i class="fa-solid fa-flag-checkered"></i> Marcar como finalizado</button>
            <div class="alert alert-warning py-2 mt-2" role="alert">Para finalizar falta: <c:if test="${not tieneFecha}">fecha</c:if><c:if test="${not tieneFecha and not tieneNota}"> y </c:if><c:if test="${not tieneNota}">nota</c:if></div>
          </c:otherwise>
        </c:choose>
      </c:if>
    </c:if>
  </div>
</div>

<c:import url="includes/footer.jsp" />
