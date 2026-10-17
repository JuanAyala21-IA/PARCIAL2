<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%--
  seguimiento.jsp (alcance por rol, igual que proyecto-ver.jsp)
  Tarjetas por fase (1-5): completada, en curso o pendiente.
  El ojo lleva a entrega.jsp?id=X&fase=N solo en fases completadas o en curso.
  Si no le corresponde -> acceso-denegado.jsp. Id inexistente -> mis-proyectos.jsp.
--%>
<c:set var="titulo" value="Seguimiento" scope="request" />
<c:set var="activo" value="proyectos" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${empty param.id}">
  <c:redirect url="mis-proyectos.jsp" />
</c:if>
<c:catch var="dbError">
  <sql:query var="ver" dataSource="${db}">
    SELECT a.id, a.codigo, a.descripcion, a.fase, a.estado, a.obs_coordinacion,
           a.fecha_sustentacion,
           DATE_FORMAT(a.fecha_sustentacion, '%d/%m/%Y') AS fecha_sus_txt,
           a.nota_sustentacion,
           a.estudiante_id, a.estudiante2_id, a.director_id, a.evaluador_id,
           (SELECT d2.nombre FROM usuarios d2 WHERE d2.id = a.director_id) AS dir_nombre,
           (SELECT v2.nombre FROM usuarios v2 WHERE v2.id = a.evaluador_id) AS eva_nombre,
           (SELECT e3.nombre FROM usuarios e3 WHERE e3.id = a.estudiante_id) AS est_nombre,
           (SELECT e3.codigo FROM usuarios e3 WHERE e3.id = a.estudiante_id) AS est_codigo,
           (SELECT e4.nombre FROM usuarios e4 WHERE e4.id = a.estudiante2_id) AS est2_nombre,
           (SELECT e4.codigo FROM usuarios e4 WHERE e4.id = a.estudiante2_id) AS est2_codigo
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

<%-- Fase actual como numero: '1'..'5' -> ese numero, 'FINAL' -> 6, otro -> 1.
     Nunca se compara el valor crudo con operadores numericos. --%>
<c:set var="faseNum" value="1" />
<c:choose>
  <c:when test="${ver.rows[0].fase == 'FINAL'}"><c:set var="faseNum" value="6" /></c:when>
  <c:when test="${ver.rows[0].fase == '1'}"><c:set var="faseNum" value="1" /></c:when>
  <c:when test="${ver.rows[0].fase == '2'}"><c:set var="faseNum" value="2" /></c:when>
  <c:when test="${ver.rows[0].fase == '3'}"><c:set var="faseNum" value="3" /></c:when>
  <c:when test="${ver.rows[0].fase == '4'}"><c:set var="faseNum" value="4" /></c:when>
  <c:when test="${ver.rows[0].fase == '5'}"><c:set var="faseNum" value="5" /></c:when>
</c:choose>

<%-- Nombre del turno actual para la insignia --%>
<c:set var="turno" value="" />
<c:if test="${ver.rows[0].estado == 'ESTUDIANTE'}"><c:set var="turno" value="Estudiante" /></c:if>
<c:if test="${ver.rows[0].estado == 'DIRECTOR'}"><c:set var="turno" value="Director" /></c:if>
<c:if test="${ver.rows[0].estado == 'EVALUADOR'}"><c:set var="turno" value="Evaluador" /></c:if>
<c:if test="${ver.rows[0].estado == 'COORDINACION' and (ver.rows[0].fase == '3' or ver.rows[0].fase == '5')}"><c:set var="turno" value="Coordinación (aval)" /></c:if>
<c:if test="${ver.rows[0].estado == 'COORDINACION' and ver.rows[0].fase != '3' and ver.rows[0].fase != '5'}"><c:set var="turno" value="Coordinación" /></c:if>

<%-- Historial de decisiones (director y evaluador) + aviso de devolución --%>
<c:if test="${ver.rowCount == 1}">
  <c:catch var="dbError2">
    <sql:query var="ultima" dataSource="${db}">
      SELECT fase, decision, observaciones, fecha,
             DATE_FORMAT(fecha, '%d/%m/%Y %H:%i') AS fecha_txt, 'Director' AS origen,
             (SELECT u2.nombre FROM usuarios u2 WHERE u2.id = r.director_id) AS revisor
      FROM revisiones r WHERE r.anteproyecto_id = ?
      UNION ALL
      SELECT fase, decision, observaciones, fecha,
             DATE_FORMAT(fecha, '%d/%m/%Y %H:%i') AS fecha_txt, 'Evaluador',
             (SELECT u2.nombre FROM usuarios u2 WHERE u2.id = e.evaluador_id)
      FROM evaluaciones e WHERE e.anteproyecto_id = ?
      UNION ALL
      SELECT fase, decision, observaciones, fecha,
             DATE_FORMAT(fecha, '%d/%m/%Y %H:%i') AS fecha_txt, 'Coordinación',
             (SELECT u2.nombre FROM usuarios u2 WHERE u2.id = v.coordinador_id)
      FROM avales v WHERE v.anteproyecto_id = ?
      ORDER BY fecha DESC
      <sql:param value="${ver.rows[0].id}" />
      <sql:param value="${ver.rows[0].id}" />
      <sql:param value="${ver.rows[0].id}" />
    </sql:query>
  </c:catch>
</c:if>
<c:set var="devuelta" value="${sessionScope.rol == 'ESTUDIANTE' and (ver.rows[0].estudiante_id == sessionScope.usuarioId or ver.rows[0].estudiante2_id == sessionScope.usuarioId) and ver.rows[0].estado == 'ESTUDIANTE' and not empty ultima and ultima.rowCount > 0 and ultima.rows[0].decision == 'DEVUELTO' and (ultima.rows[0].origen == 'Director' or ultima.rows[0].origen == 'Evaluador')}" />

<c:import url="includes/header.jsp" />
<c:import url="includes/sidebar.jsp" />

<div class="card card-lima shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
      <h4 class="mb-0">Seguimiento del <span class="badge-lima">PROYECTO</span></h4>
      <div class="d-flex gap-2 flex-wrap">
        <a href="#" class="btn btn-danger" title="Alertas"><i class="fa-solid fa-triangle-exclamation"></i></a>
        <a href="#" class="btn btn-bandera" title="Metas"><i class="fa-solid fa-flag"></i></a>
        <a href="calendario.jsp" class="btn btn-lima" title="Calendario"><i class="fa-solid fa-calendar-days"></i></a>
        <a href="#" class="btn btn-secondary" title="Configuraci&oacute;n"><i class="fa-solid fa-gear"></i></a>
        <a href="mis-proyectos.jsp" class="btn btn-lima"><i class="fa-solid fa-arrow-left"></i> Volver</a>
      </div>
    </div>
    <hr />
    <p class="text-muted">Aqu&iacute; podr&aacute;s llevar el seguimiento del progreso del proyecto de grado en curso</p>

    <c:if test="${not empty dbError}">
      <div class="alert alert-danger py-2" role="alert">Error de conexi&oacute;n. Intente de nuevo.</div>
    </c:if>
    <c:if test="${param.ok == 1}">
      <c:choose>
        <c:when test="${param.dest == 'director'}">
          <div class="alert alert-success py-2" role="alert">Fase enviada al Director.</div>
        </c:when>
        <c:otherwise>
          <div class="alert alert-success py-2" role="alert">Fase enviada a Coordinaci&oacute;n.</div>
        </c:otherwise>
      </c:choose>
    </c:if>
    <c:if test="${param.error == 'invalido'}">
      <div class="alert alert-danger py-2" role="alert">No se pudo enviar la fase. Verifique los requisitos.</div>
    </c:if>
    <c:if test="${ver.rows[0].estado == 'FINALIZADO'}">
      <div class="alert alert-success py-2" role="alert">Proyecto finalizado.</div>
    </c:if>
    <c:if test="${devuelta}">
      <div class="alert alert-warning py-2" role="alert">
        Tu <c:out value="${fn:toLowerCase(ultima.rows[0].origen)}" /> devolvi&oacute; esta entrega.
        <c:out value="${ultima.rows[0].observaciones}" />
      </div>
    </c:if>
    <c:if test="${sessionScope.rol == 'ESTUDIANTE' and (ver.rows[0].estudiante_id == sessionScope.usuarioId or ver.rows[0].estudiante2_id == sessionScope.usuarioId) and ver.rows[0].estado == 'ESTUDIANTE' and not empty ver.rows[0].obs_coordinacion}">
      <div class="alert alert-warning py-2" role="alert">
        Coordinaci&oacute;n devolvi&oacute; tu solicitud.
        <c:out value="${ver.rows[0].obs_coordinacion}" />
      </div>
    </c:if>
    <c:if test="${ver.rows[0].estado == 'EVALUADOR' and not empty ver.rows[0].obs_coordinacion and (ver.rows[0].evaluador_id == sessionScope.usuarioId or sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR')}">
      <div class="alert alert-warning py-2" role="alert">
        Coordinaci&oacute;n no aval&oacute; la aprobaci&oacute;n del evaluador.
        <c:out value="${ver.rows[0].obs_coordinacion}" />
      </div>
    </c:if>

    <p class="mb-3">
      <strong><c:out value="${ver.rows[0].codigo}" /></strong>
      &middot; <c:out value="${fn:substring(ver.rows[0].descripcion, 0, 120)}" /><c:if test="${fn:length(ver.rows[0].descripcion) > 120}">...</c:if>
      <span class="badge-turno"><c:out value="${ver.rows[0].estado}" /><c:if test="${not empty turno}"> &middot; <c:out value="${turno}" /></c:if></span>
      <c:if test="${ver.rows[0].estado == 'COORDINACION' and (ver.rows[0].fase == '3' or ver.rows[0].fase == '5')}">
        <span class="badge text-bg-warning text-nowrap">Pendiente de aval de Coordinación</span>
      </c:if>
      &middot; <small class="text-muted">Director: <c:out value="${ver.rows[0].dir_nombre}" default="Sin asignar" /> &middot; Evaluador: <c:out value="${ver.rows[0].eva_nombre}" default="Sin asignar" /></small>
      <c:if test="${sessionScope.rol == 'PROFESOR' and ver.rows[0].director_id == sessionScope.usuarioId}">
        <span class="badge-lima text-nowrap">Director</span>
      </c:if>
      <c:if test="${sessionScope.rol == 'PROFESOR' and ver.rows[0].director_id != sessionScope.usuarioId and ver.rows[0].evaluador_id == sessionScope.usuarioId}">
        <span class="badge text-bg-dark text-nowrap">Evaluador</span>
      </c:if>
    </p>
    <p class="mb-3"><small class="text-muted">
      Estudiante: <c:out value="${ver.rows[0].est_nombre}" default="&#8212;" />
      <c:if test="${not empty ver.rows[0].est_codigo}"> (<c:out value="${ver.rows[0].est_codigo}" />)</c:if>
      <c:if test="${not empty ver.rows[0].est2_nombre}">
        &middot; <span class="badge text-bg-info">Compañero(a)</span>
        <c:out value="${ver.rows[0].est2_nombre}" />
        <c:if test="${not empty ver.rows[0].est2_codigo}"> (<c:out value="${ver.rows[0].est2_codigo}" />)</c:if>
      </c:if>
    </small></p>
    <p><small>
      <button type="button" class="btn btn-sm btn-lima" data-bs-toggle="modal" data-bs-target="#modalRevisiones"><i class="fa-solid fa-clock-rotate-left"></i> Ver revisiones <span class="badge text-bg-dark"><c:out value="${ultima.rowCount}" default="0" /></span></button>
    </small></p>

    <div class="modal fade" id="modalRevisiones" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-xl modal-dialog-scrollable">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Historial de revisiones <c:out value="${ver.rows[0].codigo}" /></h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
          </div>
          <div class="modal-body">
            <c:if test="${empty ultima.rows}">
              <p class="text-muted">Aún no hay revisiones.</p>
            </c:if>
            <c:if test="${not empty ultima.rows}">
              <div class="table-responsive">
                <table class="table table-hover align-middle">
                  <thead>
                    <tr>
                      <th>Fase</th>
                      <th>Revisor</th>
                      <th>Decisi&oacute;n</th>
                      <th>Observaciones</th>
                      <th>Fecha</th>
                    </tr>
                  </thead>
                  <tbody>
                    <c:forEach var="h" items="${ultima.rows}">
                      <tr>
                        <td><span class="badge-fase text-nowrap">Fase <c:out value="${h.fase}" /></span></td>
                        <td><c:out value="${h.origen}" />: <c:out value="${h.revisor}" default="&#8212;" /></td>
                        <td>
                          <c:if test="${h.decision == 'APROBADO' or h.decision == 'AVALADO'}">
                            <span class="badge text-bg-success"><c:out value="${h.decision}" /></span>
                          </c:if>
                          <c:if test="${h.decision == 'NO_AVALADO'}">
                            <span class="badge text-bg-danger">NO AVALADO</span>
                          </c:if>
                          <c:if test="${h.decision != 'APROBADO' and h.decision != 'AVALADO' and h.decision != 'NO_AVALADO'}">
                            <span class="badge text-bg-warning"><c:out value="${h.decision}" /></span>
                          </c:if>
                        </td>
                        <td class="texto-multilinea"><c:out value="${h.observaciones}" default="&#8212;" /></td>
                        <td class="text-nowrap"><c:out value="${h.fecha_txt}" /></td>
                      </tr>
                    </c:forEach>
                  </tbody>
                </table>
              </div>
            </c:if>
          </div>
        </div>
      </div>
    </div>

    <div class="fases-grid">
      <c:forEach var="n" begin="1" end="6">
        <c:set var="faseTitulo" value="Fase Final" />
        <c:set var="faseDesc" value="Estudiantes, director y evaluador programan sustentación." />
        <c:if test="${n == 1}">
          <c:set var="faseTitulo" value="Fase 1: Pago" />
          <c:set var="faseDesc" value="El estudiante describe su idea y sube el pago." />
        </c:if>
        <c:if test="${n == 2}">
          <c:set var="faseTitulo" value="Fase 2: Propuesta I" />
          <c:set var="faseDesc" value="El estudiante envía la propuesta al director." />
        </c:if>
        <c:if test="${n == 3}">
          <c:set var="faseTitulo" value="Fase 3: Propuesta II" />
          <c:set var="faseDesc" value="El director envía propuesta a evaluador y comité." />
        </c:if>
        <c:if test="${n == 4}">
          <c:set var="faseTitulo" value="Fase 4: Informe I" />
          <c:set var="faseDesc" value="El estudiante envía el informe al director." />
        </c:if>
        <c:if test="${n == 5}">
          <c:set var="faseTitulo" value="Fase 5: Informe II" />
          <c:set var="faseDesc" value="El director envía el informe al evaluador y comité." />
        </c:if>
        <c:set var="esFinalizado" value="${ver.rows[0].estado == 'FINALIZADO'}" />
        <c:choose>
          <c:when test="${n < faseNum or (n == 6 and esFinalizado)}">
            <c:set var="faseCls" value="completada" />
            <c:set var="faseIcono" value="fa-circle-check" />
          </c:when>
          <c:when test="${n == faseNum}">
            <c:set var="faseCls" value="en-curso" />
            <c:set var="faseIcono" value="fa-hourglass-half" />
          </c:when>
          <c:otherwise>
            <c:set var="faseCls" value="pendiente" />
            <c:set var="faseIcono" value="fa-paper-plane" />
          </c:otherwise>
        </c:choose>
        <div class="fase-card ${faseCls}">
          <i class="fa-solid ${faseIcono} fase-icon"></i>
          <h5><c:out value="${faseTitulo}" /></h5>
          <p><c:out value="${faseDesc}" /></p>
          <c:if test="${n == 6 and n <= faseNum}">
            <c:url var="urlSus" value="sustentacion.jsp">
              <c:param name="id" value="${ver.rows[0].id}" />
            </c:url>
            <a href="${urlSus}" class="btn btn-sm btn-dark" title="Ver sustentación"><i class="fa-solid fa-eye"></i></a>
            <small class="text-muted">Sustentación: <c:out value="${ver.rows[0].fecha_sus_txt}" default="&#8212;" /></small>
            <c:if test="${not empty ver.rows[0].nota_sustentacion}">
              <small class="text-muted">Nota: <c:out value="${ver.rows[0].nota_sustentacion}" /></small>
            </c:if>
          </c:if>
          <c:if test="${n <= 5 and n <= faseNum}">
            <c:url var="urlEntrega" value="entrega.jsp">
              <c:param name="id" value="${ver.rows[0].id}" />
              <c:param name="fase" value="${n}" />
            </c:url>
            <a href="${urlEntrega}" class="btn btn-sm btn-dark" title="Ver entregas"><i class="fa-solid fa-eye"></i></a>
          </c:if>
        </div>
      </c:forEach>
    </div>
  </div>
</div>

<c:import url="includes/footer.jsp" />
