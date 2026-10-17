<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  calendario.jsp (todos los roles autenticados)
  Filtro por mes/año (GET, por defecto el actual desde CURDATE()).
  Eventos del mes agrupados por día, hoy resaltado, y próximos 5 eventos.
  Crear/editar/eliminar solo COORDINACION y ADMINISTRADOR.
--%>
<c:set var="titulo" value="Calendario académico" scope="request" />
<c:set var="activo" value="calendario" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:set var="puedeGestionar" value="${sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR'}" scope="request" />

<%-- Fecha actual desde la BD (sin beans Java) --%>
<c:catch var="dbError">
  <sql:query var="f" dataSource="${db}">
    SELECT CURDATE() AS hoy, MONTH(CURDATE()) AS mes_actual, YEAR(CURDATE()) AS anio_actual
  </sql:query>
</c:catch>
<fmt:formatDate var="hoyStr" value="${f.rows[0].hoy}" pattern="yyyy-MM-dd" />
<c:set var="mes" value="${f.rows[0].mes_actual}" />
<c:if test="${param.mes >= 1 and param.mes <= 12}">
  <c:set var="mes" value="${param.mes * 1}" />
</c:if>
<c:set var="anio" value="${f.rows[0].anio_actual}" />
<c:if test="${param.anio >= 2000 and param.anio <= 2100}">
  <c:set var="anio" value="${param.anio * 1}" />
</c:if>
<c:set var="meses" value="Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre" />
<c:set var="mesNombre" value="${fn:split(meses, ',')[mes - 1]}" />

<%-- Eventos del mes consultado --%>
<c:catch var="dbError2">
  <sql:query var="eventos" dataSource="${db}">
    SELECT id, titulo, descripcion, tipo, fecha_inicio, fecha_fin FROM calendario
    WHERE fecha_inicio <= LAST_DAY(CONCAT(?, '-', ?, '-01'))
      AND (fecha_fin IS NULL OR fecha_fin >= CONCAT(?, '-', ?, '-01'))
    ORDER BY fecha_inicio, id
    <sql:param value="${anio}" />
    <sql:param value="${mes}" />
    <sql:param value="${anio}" />
    <sql:param value="${mes}" />
  </sql:query>
</c:catch>

<%-- Próximos 5 eventos desde hoy --%>
<c:catch var="dbError3">
  <sql:query var="proximos" dataSource="${db}">
    SELECT id, titulo, tipo, fecha_inicio, fecha_fin FROM calendario
    WHERE fecha_inicio >= CURDATE()
    ORDER BY fecha_inicio, id LIMIT 5
  </sql:query>
</c:catch>

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Calendario <span class="badge-lima">ACAD&Eacute;MICO</span></h4>
      <c:if test="${puedeGestionar}">
        <a href="evento-form.jsp" class="btn btn-lima"><i class="fa-solid fa-plus"></i> Nuevo evento</a>
      </c:if>
    </div>
    <hr />

    <c:if test="${param.ok == 1}">
      <div class="alert alert-success py-2" role="alert">Evento registrado.</div>
    </c:if>
    <c:if test="${param.ok == 2}">
      <div class="alert alert-success py-2" role="alert">Evento actualizado.</div>
    </c:if>
    <c:if test="${param.ok == 3}">
      <div class="alert alert-success py-2" role="alert">Evento eliminado.</div>
    </c:if>
    <c:if test="${not empty dbError or not empty dbError2 or not empty dbError3}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>

    <form method="get" action="calendario.jsp" class="tabla-toolbar mb-3">
      <h5 class="mb-0"><c:out value="${mesNombre}" /> de <c:out value="${anio}" /></h5>
      <div class="d-flex align-items-center gap-2">
        <label for="mes" class="text-nowrap">Mes:</label>
        <select id="mes" name="mes" class="form-select form-select-sm w-auto" onchange="this.form.submit()">
          <c:forEach var="m" begin="1" end="12">
            <option value="${m}" ${m == mes ? 'selected' : ''}><c:out value="${fn:split(meses, ',')[m - 1]}" /></option>
          </c:forEach>
        </select>
        <label for="anio" class="text-nowrap">A&ntilde;o:</label>
        <select id="anio" name="anio" class="form-select form-select-sm w-auto" onchange="this.form.submit()">
          <c:forEach var="a" begin="${f.rows[0].anio_actual - 2}" end="${f.rows[0].anio_actual + 2}">
            <option value="${a}" ${a == anio ? 'selected' : ''}><c:out value="${a}" /></option>
          </c:forEach>
        </select>
      </div>
    </form>

    <c:if test="${empty eventos.rows}">
      <p class="text-muted">No hay eventos en este mes.</p>
    </c:if>
    <c:set var="diaPrevio" value="" />
    <c:forEach var="ev" items="${eventos.rows}">
      <fmt:formatDate var="diaActual" value="${ev.fecha_inicio}" pattern="yyyy-MM-dd" />
      <c:if test="${diaActual != diaPrevio}">
        <h5 class="mt-3"><fmt:formatDate value="${ev.fecha_inicio}" pattern="EEEE d 'de' MMMM" /></h5>
        <c:set var="diaPrevio" value="${diaActual}" />
      </c:if>
      <div class="card mb-2 ${diaActual == hoyStr ? 'evento-hoy' : ''}">
        <div class="card-body py-2 d-flex justify-content-between align-items-center gap-2 flex-wrap">
          <div>
            <p class="mb-1">
              <span class="badge evento-fecha"><fmt:formatDate value="${ev.fecha_inicio}" pattern="d MMM" /></span>
              <strong><c:out value="${ev.titulo}" /></strong>
              <c:if test="${ev.tipo == 'ENTREGA'}"><span class="badge text-bg-success">ENTREGA</span></c:if>
              <c:if test="${ev.tipo == 'REUNION'}"><span class="badge text-bg-primary">REUNI&Oacute;N</span></c:if>
              <c:if test="${ev.tipo == 'SUSTENTACION'}"><span class="badge text-bg-warning">SUSTENTACI&Oacute;N</span></c:if>
              <c:if test="${ev.tipo != 'ENTREGA' and ev.tipo != 'REUNION' and ev.tipo != 'SUSTENTACION'}"><span class="badge text-bg-secondary"><c:out value="${ev.tipo}" /></span></c:if>
            </p>
            <c:if test="${not empty ev.descripcion}">
              <p class="mb-1 text-muted"><c:out value="${ev.descripcion}" /></p>
            </c:if>
            <c:if test="${not empty ev.fecha_fin}">
              <small class="text-muted">Hasta el <fmt:formatDate value="${ev.fecha_fin}" pattern="dd/MM/yyyy" /></small>
            </c:if>
          </div>
          <c:if test="${puedeGestionar}">
            <div class="text-nowrap">
              <c:url var="urlEditar" value="evento-form.jsp">
                <c:param name="id" value="${ev.id}" />
              </c:url>
              <a href="${urlEditar}" class="btn btn-sm btn-lima" title="Editar"><i class="fa-solid fa-pen"></i></a>
              <button type="button" class="btn btn-sm btn-danger" title="Eliminar"
                      data-bs-toggle="modal" data-bs-target="#modalEliminar${ev.id}"><i class="fa-solid fa-trash"></i></button>
            </div>
          </c:if>
        </div>
      </div>
      <c:if test="${puedeGestionar}">
        <div class="modal fade" id="modalEliminar${ev.id}" tabindex="-1" aria-hidden="true">
          <div class="modal-dialog">
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title">Confirmar eliminaci&oacute;n</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
              </div>
              <div class="modal-body">
                &iquest;Eliminar el evento <strong><c:out value="${ev.titulo}" /></strong>?
              </div>
              <div class="modal-footer">
                <form method="post" action="evento-eliminar.jsp">
                  <input type="hidden" name="id" value="${ev.id}" />
                  <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                  <button type="submit" class="btn btn-danger">Eliminar</button>
                </form>
              </div>
            </div>
          </div>
        </div>
      </c:if>
    </c:forEach>

    <h5 class="mt-4">Pr&oacute;ximos eventos</h5>
    <c:if test="${empty proximos.rows}">
      <p class="text-muted">No hay pr&oacute;ximos eventos.</p>
    </c:if>
    <c:forEach var="px" items="${proximos.rows}">
      <div class="card mb-2">
        <div class="card-body py-2">
          <p class="mb-0">
            <span class="badge evento-fecha"><fmt:formatDate value="${px.fecha_inicio}" pattern="d MMM" /></span>
            <strong><c:out value="${px.titulo}" /></strong>
            <small class="text-muted">(<c:out value="${px.tipo}" />)</small>
          </p>
        </div>
      </div>
    </c:forEach>
  </div>
</div>

<c:import url="includes/footer.jsp" />
