<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  proyecto-ver.jsp (alcance por rol, solo lectura)
  ESTUDIANTE/DIRECTOR/EVALUADOR solo ven sus proyectos;
  COORDINACION y ADMINISTRADOR ven todos.
  Sin alcance -> acceso-denegado.jsp. Id inexistente -> mis-proyectos.jsp.
--%>
<c:set var="titulo" value="Ver proyecto" scope="request" />
<c:set var="activo" value="proyectos" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${empty param.id}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:catch var="dbError">
  <sql:query var="ver" dataSource="${db}">
    SELECT a.id, a.codigo, a.descripcion, a.fase, a.estado,
           a.estudiante_id, a.estudiante2_id, a.director_id, a.evaluador_id,
           (SELECT i2.titulo FROM ideas i2 WHERE i2.id = a.idea_id) AS idea,
           (SELECT i3.titulo FROM ideas i3 WHERE i3.id = a.idea_solicitada_id) AS solicitada,
           (SELECT i3.estado FROM ideas i3 WHERE i3.id = a.idea_solicitada_id) AS solicitada_estado,
           (SELECT e2.nombre FROM usuarios e2 WHERE e2.id = a.estudiante_id) AS est_nombre,
           (SELECT e2.correo FROM usuarios e2 WHERE e2.id = a.estudiante_id) AS est_correo,
           (SELECT e2.nombre FROM usuarios e2 WHERE e2.id = a.estudiante2_id) AS est2_nombre,
           (SELECT e2.codigo FROM usuarios e2 WHERE e2.id = a.estudiante2_id) AS est2_codigo,
           (SELECT d2.nombre FROM usuarios d2 WHERE d2.id = a.director_id) AS dir_nombre,
           (SELECT d2.correo FROM usuarios d2 WHERE d2.id = a.director_id) AS dir_correo,
           (SELECT v2.nombre FROM usuarios v2 WHERE v2.id = a.evaluador_id) AS eva_nombre,
           (SELECT v2.correo FROM usuarios v2 WHERE v2.id = a.evaluador_id) AS eva_correo,
           a.fecha_sustentacion,
           DATE_FORMAT(a.fecha_sustentacion, '%d/%m/%Y') AS fecha_sus_txt,
           a.nota_sustentacion
    FROM anteproyectos a
    WHERE a.id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${empty dbError and ver.rowCount == 0}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>

<%-- Control de alcance por rol --%>
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

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<c:set var="turno" value="" />
<c:if test="${ver.rows[0].estado == 'ESTUDIANTE'}"><c:set var="turno" value="Estudiante" /></c:if>
<c:if test="${ver.rows[0].estado == 'DIRECTOR'}"><c:set var="turno" value="Director" /></c:if>
<c:if test="${ver.rows[0].estado == 'EVALUADOR'}"><c:set var="turno" value="Evaluador" /></c:if>
<c:if test="${ver.rows[0].estado == 'COORDINACION' and (ver.rows[0].fase == '3' or ver.rows[0].fase == '5')}"><c:set var="turno" value="Coordinación (aval)" /></c:if>
<c:if test="${ver.rows[0].estado == 'COORDINACION' and ver.rows[0].fase != '3' and ver.rows[0].fase != '5'}"><c:set var="turno" value="Coordinación" /></c:if>

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Detalle del <span class="badge-lima">PROYECTO</span></h4>
      <a href="mis-proyectos.jsp" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${not empty dbError}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>
    <c:if test="${param.ok == 4}">
      <div class="alert alert-success py-2" role="alert">Proyecto iniciado. Registra tu enlace de pago y elige tu idea.</div>
    </c:if>
    <c:if test="${param.ok == 5}">
      <div class="alert alert-success py-2" role="alert">Idea guardada.</div>
    </c:if>
    <c:if test="${param.error == 'invalido'}">
      <div class="alert alert-danger py-2" role="alert">No se pudo procesar la solicitud. Verifique los datos.</div>
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
        <dt class="col-sm-3">Idea solicitada</dt>
        <dd class="col-sm-9">
          <c:out value="${ver.rows[0].solicitada}" default="&#8212;" />
          <c:if test="${ver.rows[0].solicitada_estado == 'POSTULADA'}">
            <span class="badge text-bg-info">Propuesta por el estudiante</span>
          </c:if>
        </dd>
        <dt class="col-sm-3">Idea asignada</dt>
        <dd class="col-sm-9">
          <c:choose>
            <c:when test="${not empty ver.rows[0].idea}"><c:out value="${ver.rows[0].idea}" /></c:when>
            <c:otherwise><span class="text-muted">Sin asignar</span></c:otherwise>
          </c:choose>
        </dd>
        <dt class="col-sm-3">Fase</dt>
        <dd class="col-sm-9"><span class="badge-fase">Fase <c:out value="${ver.rows[0].fase}" /></span>
          <c:if test="${sessionScope.rol == 'PROFESOR' and ver.rows[0].director_id == sessionScope.usuarioId}">
            <span class="badge-lima">Director</span>
          </c:if>
          <c:if test="${sessionScope.rol == 'PROFESOR' and ver.rows[0].director_id != sessionScope.usuarioId and ver.rows[0].evaluador_id == sessionScope.usuarioId}">
            <span class="badge text-bg-dark">Evaluador</span>
          </c:if>
        </dd>
        <dt class="col-sm-3">Estado</dt>
        <dd class="col-sm-9">
          <span class="badge-turno"><c:out value="${ver.rows[0].estado}" /><c:if test="${not empty turno}"> &middot; <c:out value="${turno}" /></c:if></span>
        </dd>
      </dl>

      <div class="card mt-3">
        <div class="card-header"><i class="fa-solid fa-graduation-cap"></i> Sustentaci&oacute;n</div>
        <div class="card-body">
          <p class="mb-1">Fecha:
            <c:choose>
              <c:when test="${not empty ver.rows[0].fecha_sustentacion}"><c:out value="${ver.rows[0].fecha_sus_txt}" /></c:when>
              <c:otherwise><span class="text-muted">Sin registrar</span></c:otherwise>
            </c:choose>
          </p>
          <p class="mb-0">Nota:
            <c:choose>
              <c:when test="${not empty ver.rows[0].nota_sustentacion}"><c:out value="${ver.rows[0].nota_sustentacion}" /></c:when>
              <c:otherwise><span class="text-muted">Sin registrar</span></c:otherwise>
            </c:choose>
          </p>
        </div>
      </div>

      <div class="row g-3 mt-1">
        <div class="col-md-4">
          <div class="card h-100">
            <div class="card-header"><i class="fa-solid fa-user-graduate"></i> Estudiante</div>
            <div class="card-body">
              <c:choose>
                <c:when test="${not empty ver.rows[0].est_nombre}">
                  <p class="mb-1"><strong><c:out value="${ver.rows[0].est_nombre}" /></strong></p>
                  <p class="mb-0 text-muted"><c:out value="${ver.rows[0].est_correo}" /></p>
                  <c:if test="${not empty ver.rows[0].est2_nombre}">
                    <hr class="my-2" />
                    <p class="mb-0">
                      <span class="badge text-bg-info">Compañero(a)</span>
                      <strong><c:out value="${ver.rows[0].est2_nombre}" /></strong>
                      <c:if test="${not empty ver.rows[0].est2_codigo}"> (<c:out value="${ver.rows[0].est2_codigo}" />)</c:if>
                    </p>
                  </c:if>
                </c:when>
                <c:otherwise>
                  <p class="mb-0 text-muted">Sin asignar</p>
                </c:otherwise>
              </c:choose>
            </div>
          </div>
        </div>
        <div class="col-md-4">
          <div class="card h-100">
            <div class="card-header"><i class="fa-solid fa-chalkboard-user"></i> Director</div>
            <div class="card-body">
              <c:choose>
                <c:when test="${not empty ver.rows[0].dir_nombre}">
                  <p class="mb-1"><strong><c:out value="${ver.rows[0].dir_nombre}" /></strong></p>
                  <p class="mb-0 text-muted"><c:out value="${ver.rows[0].dir_correo}" /></p>
                </c:when>
                <c:otherwise>
                  <p class="mb-0 text-muted">Sin asignar</p>
                </c:otherwise>
              </c:choose>
            </div>
          </div>
        </div>
        <div class="col-md-4">
          <div class="card h-100">
            <div class="card-header"><i class="fa-solid fa-clipboard-check"></i> Evaluador</div>
            <div class="card-body">
              <c:choose>
                <c:when test="${not empty ver.rows[0].eva_nombre}">
                  <p class="mb-1"><strong><c:out value="${ver.rows[0].eva_nombre}" /></strong></p>
                  <p class="mb-0 text-muted"><c:out value="${ver.rows[0].eva_correo}" /></p>
                </c:when>
                <c:otherwise>
                  <p class="mb-0 text-muted">Sin asignar</p>
                </c:otherwise>
              </c:choose>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-3 d-flex gap-2 flex-wrap">
        <c:url var="urlAte" value="atender-solicitud.jsp">
          <c:param name="id" value="${ver.rows[0].id}" />
        </c:url>
        <c:url var="urlRev" value="revisar.jsp">
          <c:param name="id" value="${ver.rows[0].id}" />
        </c:url>
        <c:url var="urlEv" value="evaluar.jsp">
          <c:param name="id" value="${ver.rows[0].id}" />
        </c:url>
        <c:url var="urlAva" value="avalar.jsp">
          <c:param name="id" value="${ver.rows[0].id}" />
        </c:url>
        <c:if test="${(sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR') and ver.rows[0].fase == '1' and ver.rows[0].estado == 'COORDINACION'}">
          <a href="${urlAte}" class="btn btn-lima"><i class="fa-solid fa-inbox"></i> Atender solicitud</a>
        </c:if>
        <c:if test="${(sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR') and (ver.rows[0].fase == '3' or ver.rows[0].fase == '5') and ver.rows[0].estado == 'COORDINACION'}">
          <a href="${urlAva}" class="btn btn-lima"><i class="fa-solid fa-file-signature"></i> Avalar</a>
        </c:if>
        <c:if test="${sessionScope.rol == 'PROFESOR' and ver.rows[0].director_id == sessionScope.usuarioId and ver.rows[0].estado == 'DIRECTOR' and (ver.rows[0].fase == '2' or ver.rows[0].fase == '4')}">
          <a href="${urlRev}" class="btn btn-lima"><i class="fa-solid fa-check-double"></i> Revisar</a>
        </c:if>
        <c:if test="${sessionScope.rol == 'PROFESOR' and ver.rows[0].evaluador_id == sessionScope.usuarioId and ver.rows[0].estado == 'EVALUADOR' and (ver.rows[0].fase == '3' or ver.rows[0].fase == '5')}">
          <a href="${urlEv}" class="btn btn-lima"><i class="fa-solid fa-clipboard-check"></i> Evaluar</a>
        </c:if>
        <a href="mis-proyectos.jsp" class="btn btn-outline-secondary">Volver</a>
      </div>
    </c:if>
  </div>
</div>

<c:import url="includes/footer.jsp" />
