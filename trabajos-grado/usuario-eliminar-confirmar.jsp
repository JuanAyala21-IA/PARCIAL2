<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  usuario-eliminar-confirmar.jsp (solo ADMINISTRADOR, GET, con layout)
  Paso 2 del borrado de usuarios: resumen de lo que se eliminara o transferira.
  - Muestra los conteos (subconsultas escalares con alias unicos) de las 9 relaciones.
  - "Marcar como INACTIVO/ACTIVO": POST a usuario-estado.jsp.
  - "Eliminar definitivamente": POST a usuario-eliminar-definitivo.jsp escribiendo ELIMINAR.
  - PROFESOR / COORDINACION / ADMINISTRADOR con registros: select obligatorio de heredero
    (solo herederos validos). Sin herederos disponibles: borrado deshabilitado.
  - La FK no cubierta y los residuales no transferibles bloquean (los informa el POST).
--%>
<c:set var="titulo" value="Eliminar usuario" scope="request" />
<c:set var="activo" value="usuarios" scope="request" />
<c:set var="rolesPermitidos" value="ADMINISTRADOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${empty param.id}">
  <c:redirect url="usuarios.jsp" />
</c:if>

<c:catch var="dbError">
  <sql:query var="usr" dataSource="${db}">
    SELECT u.id, u.codigo, u.nombre, u.correo, u.estado,
           (SELECT r.nombre FROM roles r WHERE r.id = u.rol_id) AS rol
    FROM usuarios u
    WHERE u.id = ?
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>
<c:if test="${empty dbError and usr.rowCount == 0}">
  <c:redirect url="usuarios.jsp" />
</c:if>

<%-- Resumen de relaciones (conteos con alias unicos) --%>
<c:catch var="sumError">
  <sql:query var="sum" dataSource="${db}">
    SELECT
      (SELECT COUNT(*) FROM anteproyectos WHERE estudiante_id = ?) AS n_principal,
      (SELECT COUNT(*) FROM anteproyectos WHERE estudiante_id = ? AND estudiante2_id IS NOT NULL) AS n_con_companero,
      (SELECT COUNT(*) FROM anteproyectos WHERE estudiante2_id = ?) AS n_companero,
      (SELECT COUNT(*) FROM anteproyectos WHERE director_id = ?) AS n_director,
      (SELECT COUNT(*) FROM anteproyectos WHERE evaluador_id = ?) AS n_evaluador,
      (SELECT COUNT(*) FROM entregas WHERE enviado_por = ?) AS n_enlaces,
      (SELECT COUNT(*) FROM revisiones WHERE director_id = ?) AS n_revisiones,
      (SELECT COUNT(*) FROM evaluaciones WHERE evaluador_id = ?) AS n_evaluaciones,
      (SELECT COUNT(*) FROM avales WHERE coordinador_id = ?) AS n_avales,
      (SELECT COUNT(*) FROM ideas WHERE propuesta_por = ?) AS n_ideas
    <sql:param value="${param.id}" />
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

<%-- Proyectos como estudiante principal, con su codigo GRA y companero --%>
<c:catch var="prjError">
  <sql:query var="prj" dataSource="${db}">
    SELECT a.codigo,
           (SELECT u2.nombre FROM usuarios u2 WHERE u2.id = a.estudiante2_id) AS companero_nombre
    FROM anteproyectos a
    WHERE a.estudiante_id = ?
    ORDER BY a.id
    <sql:param value="${param.id}" />
  </sql:query>
</c:catch>

<c:set var="relTotal" value="${0}" />
<c:if test="${empty sumError}">
  <c:set var="relTotal" value="${sum.rows[0].n_principal + sum.rows[0].n_companero + sum.rows[0].n_director + sum.rows[0].n_evaluador + sum.rows[0].n_enlaces + sum.rows[0].n_revisiones + sum.rows[0].n_evaluaciones + sum.rows[0].n_avales + sum.rows[0].n_ideas}" />
</c:if>

<%-- PROFESOR / COORDINACION / ADMINISTRADOR con historial: heredero obligatorio --%>
<c:set var="requiereHeredero" value="${empty sumError and relTotal > 0 and (usr.rows[0].rol == 'PROFESOR' or usr.rows[0].rol == 'COORDINACION' or usr.rows[0].rol == 'ADMINISTRADOR')}" />
<c:set var="hayHeredero" value="${false}" />
<c:if test="${requiereHeredero}">
  <c:choose>
    <c:when test="${usr.rows[0].rol == 'PROFESOR'}">
      <%-- Otro PROFESOR ACTIVO que no sea el otro responsable en ningun proyecto del usuario --%>
      <c:catch var="herError">
        <sql:query var="her" dataSource="${db}">
          SELECT u.id, u.nombre, u.codigo
          FROM usuarios u
          JOIN roles r ON r.id = u.rol_id
          WHERE r.nombre = 'PROFESOR' AND u.estado = 'ACTIVO' AND u.id <> ?
            AND NOT EXISTS (
              SELECT 1 FROM anteproyectos a
              WHERE (a.director_id = ? AND a.evaluador_id = u.id)
                 OR (a.evaluador_id = ? AND a.director_id = u.id))
          ORDER BY u.nombre
          <sql:param value="${param.id}" />
          <sql:param value="${param.id}" />
          <sql:param value="${param.id}" />
        </sql:query>
      </c:catch>
    </c:when>
    <c:otherwise>
      <%-- COORDINACION o ADMINISTRADOR: otro usuario activo de Coordinacion o Administracion --%>
      <c:catch var="herError">
        <sql:query var="her" dataSource="${db}">
          SELECT u.id, u.nombre, u.codigo
          FROM usuarios u
          JOIN roles r ON r.id = u.rol_id
          WHERE (r.nombre = 'COORDINACION' OR r.nombre = 'ADMINISTRADOR') AND u.estado = 'ACTIVO' AND u.id <> ?
          ORDER BY r.nombre, u.nombre
          <sql:param value="${param.id}" />
        </sql:query>
      </c:catch>
    </c:otherwise>
  </c:choose>
  <c:if test="${empty herError and her.rowCount > 0}">
    <c:set var="hayHeredero" value="${true}" />
  </c:if>
</c:if>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Eliminar <span class="badge-lima">USUARIO</span></h4>
      <a href="usuarios.jsp" class="btn btn-outline-secondary"><i class="fa-solid fa-arrow-left"></i> Volver</a>
    </div>
    <hr />

    <c:if test="${not empty dbError or not empty sumError}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <c:if test="${empty dbError and usr.rowCount == 1}">
      <%-- Alertas de las revalidaciones del servidor --%>
      <c:if test="${param.error == 'propio'}">
        <div class="alert alert-danger py-2" role="alert">No puedes eliminarte a ti mismo.</div>
      </c:if>
      <c:if test="${param.error == 'ultimo-admin'}">
        <div class="alert alert-danger py-2" role="alert">No puedes eliminar al &uacute;nico administrador.</div>
      </c:if>
      <c:if test="${param.error == 'confirmacion'}">
        <div class="alert alert-danger py-2" role="alert">Debes escribir exactamente <strong>ELIMINAR</strong> para confirmar la eliminaci&oacute;n.</div>
      </c:if>
      <c:if test="${param.error == 'heredero' and param.motivo == 'estudiante'}">
        <div class="alert alert-danger py-2" role="alert">Este estudiante tiene ideas propuestas referenciadas por otros proyectos y no hay heredero a quien transferirlas; no se puede eliminar definitivamente.</div>
      </c:if>
      <c:if test="${param.error == 'heredero' and param.motivo != 'estudiante'}">
        <div class="alert alert-danger py-2" role="alert">Selecciona un heredero v&aacute;lido para transferir su historial.</div>
      </c:if>
      <c:if test="${param.error == 'nocubierta'}">
        <div class="alert alert-danger py-2" role="alert">No se puede eliminar definitivamente: la relaci&oacute;n <strong><c:out value="${param.tabla}" /></strong> referencia a usuarios y no est&aacute; cubierta por las reglas de eliminaci&oacute;n.</div>
      </c:if>
      <c:if test="${param.error == 'residual'}">
        <div class="alert alert-danger py-2" role="alert">No se puede eliminar definitivamente: quedan registros en <strong><c:out value="${param.tabla}" /></strong> que las reglas no cubren. Puedes marcarlo como INACTIVO.</div>
      </c:if>
      <c:if test="${param.error == 'invalido'}">
        <div class="alert alert-danger py-2" role="alert">No se pudo completar la eliminaci&oacute;n y no se cambi&oacute; ning&uacute;n registro. Intente de nuevo.</div>
      </c:if>
      <c:if test="${param.error == 'conexion'}">
        <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
      </c:if>

      <p class="mb-1">Usuario: <strong><c:out value="${usr.rows[0].nombre}" /></strong>
        (<c:out value="${usr.rows[0].codigo}" default="&#8212;" />) &mdash; <c:out value="${usr.rows[0].correo}" /></p>
      <p class="mb-3">Rol: <span class="rol-badge"><c:out value="${usr.rows[0].rol}" /></span>
        &mdash; Estado:
        <c:if test="${usr.rows[0].estado == 'ACTIVO'}">
          <span class="badge text-bg-success">ACTIVO</span>
        </c:if>
        <c:if test="${usr.rows[0].estado != 'ACTIVO'}">
          <span class="badge text-bg-secondary"><c:out value="${usr.rows[0].estado}" /></span>
        </c:if>
      </p>

      <h6>Resumen de registros relacionados</h6>
      <dl class="row mb-2">
        <dt class="col-sm-6">Proyectos como estudiante principal</dt>
        <dd class="col-sm-6">${sum.rows[0].n_principal} <span class="text-muted">(con compa&ntilde;ero(a): ${sum.rows[0].n_con_companero})</span></dd>
        <dt class="col-sm-6">Proyectos como compa&ntilde;ero(a)</dt>
        <dd class="col-sm-6">${sum.rows[0].n_companero}</dd>
        <dt class="col-sm-6">Proyectos como director</dt>
        <dd class="col-sm-6">${sum.rows[0].n_director}</dd>
        <dt class="col-sm-6">Proyectos como evaluador</dt>
        <dd class="col-sm-6">${sum.rows[0].n_evaluador}</dd>
        <dt class="col-sm-6">Enlaces subidos</dt>
        <dd class="col-sm-6">${sum.rows[0].n_enlaces}</dd>
        <dt class="col-sm-6">Revisiones</dt>
        <dd class="col-sm-6">${sum.rows[0].n_revisiones}</dd>
        <dt class="col-sm-6">Evaluaciones</dt>
        <dd class="col-sm-6">${sum.rows[0].n_evaluaciones}</dd>
        <dt class="col-sm-6">Avales</dt>
        <dd class="col-sm-6">${sum.rows[0].n_avales}</dd>
        <dt class="col-sm-6">Ideas propuestas</dt>
        <dd class="col-sm-6">${sum.rows[0].n_ideas}</dd>
      </dl>

      <c:if test="${not empty prj.rows}">
        <p class="mb-1"><strong>Proyectos como estudiante principal:</strong></p>
        <ul class="mb-3">
          <c:forEach var="p" items="${prj.rows}">
            <li>GRA <strong><c:out value="${p.codigo}" /></strong>
              <c:choose>
                <c:when test="${empty p.companero_nombre}"> &mdash; sin compa&ntilde;ero(a): el proyecto y sus entregas, revisiones, evaluaciones y avales se eliminan.</c:when>
                <c:otherwise> &mdash; compa&ntilde;ero(a) <strong><c:out value="${p.companero_nombre}" /></strong> pasa a ser el principal y conserva el proyecto.</c:otherwise>
              </c:choose>
            </li>
          </c:forEach>
        </ul>
      </c:if>

      <c:if test="${usr.rows[0].rol == 'ESTUDIANTE'}">
        <p class="text-muted mb-3">Como estudiante: en sus proyectos con compa&ntilde;ero(a), todas las entregas y las ideas propuestas por &eacute;l pasan al nuevo principal; en los proyectos sin compa&ntilde;ero(a), el proyecto y sus registros se eliminan; la idea del banco asignada vuelve a DISPONIBLE; las ideas suyas sin proyecto se eliminan.</p>
      </c:if>
      <c:if test="${requiereHeredero}">
        <p class="text-muted mb-3">Como <c:out value="${usr.rows[0].rol}" />: sus proyectos como director y evaluador, revisiones, evaluaciones, enlaces, avales e ideas se transferir&aacute;n al heredero que elijas.</p>
      </c:if>

      <%-- Accion 1: marcar como INACTIVO (o ACTIVO si ya esta inactivo) --%>
      <c:if test="${param.id != sessionScope.usuarioId}">
        <form method="post" action="usuario-estado.jsp" class="mb-3">
          <input type="hidden" name="id" value="${usr.rows[0].id}" />
          <c:choose>
            <c:when test="${usr.rows[0].estado == 'ACTIVO'}">
              <input type="hidden" name="accion" value="inactivar" />
              <button type="submit" class="btn btn-outline-secondary"><i class="fa-solid fa-user-slash"></i> Marcar como INACTIVO</button>
            </c:when>
            <c:otherwise>
              <input type="hidden" name="accion" value="activar" />
              <button type="submit" class="btn btn-outline-secondary"><i class="fa-solid fa-user-check"></i> Marcar como ACTIVO</button>
            </c:otherwise>
          </c:choose>
        </form>
      </c:if>

      <%-- Accion 2: eliminacion definitiva --%>
      <c:choose>
        <c:when test="${not requiereHeredero or hayHeredero}">
          <form method="post" action="usuario-eliminar-definitivo.jsp" class="border border-danger rounded p-3">
            <h6 class="text-danger mb-2">Eliminar definitivamente</h6>
            <div class="alert alert-danger py-2" role="alert">Esta acci&oacute;n no se puede deshacer. Se recomienda exportar la base de datos antes.</div>
            <input type="hidden" name="id" value="${usr.rows[0].id}" />
            <c:if test="${requiereHeredero}">
              <label class="form-label" for="heredero">Transferir su historial a: <span class="text-danger">*</span></label>
              <select id="heredero" name="heredero_id" class="form-select mb-2" required>
                <option value="">Seleccione un usuario</option>
                <c:forEach var="h" items="${her.rows}">
                  <option value="${h.id}"><c:out value="${h.nombre}" /> (<c:out value="${h.codigo}" default="sin c&oacute;digo" />)</option>
                </c:forEach>
              </select>
            </c:if>
            <label class="form-label" for="texto">Escribe <strong>ELIMINAR</strong> para confirmar: <span class="text-danger">*</span></label>
            <input type="text" id="texto" name="confirmar_texto" class="form-control mb-2" required autocomplete="off" />
            <button type="submit" class="btn btn-danger"><i class="fa-solid fa-trash"></i> Eliminar definitivamente</button>
          </form>
        </c:when>
        <c:otherwise>
          <div class="alert alert-warning py-2" role="alert">No hay otro usuario disponible para recibir su historial; m&aacute;rcalo como INACTIVO.</div>
        </c:otherwise>
      </c:choose>
    </c:if>
  </div>
</div>

<c:import url="includes/footer.jsp" />
