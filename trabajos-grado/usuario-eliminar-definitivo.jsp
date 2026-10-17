<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  usuario-eliminar-definitivo.jsp (solo ADMINISTRADOR, solo POST, sin HTML)
  Paso 3: eliminacion definitiva con historial, en UNA sola sql:transaction.
  Revalida: texto == ELIMINAR, usuario existente, no es el propio, no es el ultimo
  administrador activo, heredero valido cuando aplica, ninguna FK no cubierta.
  Reglas por tipo de relacion:
  - ESTUDIANTE principal con companero: el companero pasa a principal y las entregas
    y las ideas propuestas del usuario en ese proyecto pasan al nuevo principal.
  - ESTUDIANTE principal sin companero: se eliminan avales, evaluaciones, revisiones,
    entregas y el proyecto; la idea del banco ASIGNADA vuelve a DISPONIBLE; la idea
    postulada por el usuario se elimina.
  - ESTUDIANTE companero: estudiante2_id = NULL y sus entregas pasan al principal.
  - Ideas restantes sin proyecto: se eliminan.
  - PROFESOR / COORDINACION / ADMINISTRADOR: TODAS las relaciones se transfieren
    al heredero elegido (proyectos como director/evaluador, revisiones, evaluaciones,
    entregas, avales e ideas).
  Cualquier fallo revierte todo y vuelve a la confirmacion con alerta roja.
--%>
<c:set var="rolesPermitidos" value="ADMINISTRADOR" scope="request" />

<%@ include file="includes/guard.jspf" %>
<c:import url="includes/conexion.jsp" />

<c:if test="${pageContext.request.method != 'POST' or empty param.id}">
  <c:redirect url="usuarios.jsp" />
</c:if>

<%-- Revalidacion 1: texto de confirmacion exacto --%>
<c:if test="${param.confirmar_texto != 'ELIMINAR'}">
  <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=confirmacion" />
</c:if>

<%-- Revalidacion 2: usuario existente --%>
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
  <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=conexion" />
</c:if>
<c:if test="${usr.rowCount == 0}">
  <c:redirect url="usuarios.jsp" />
</c:if>

<%-- Revalidacion 3: no es el propio usuario --%>
<c:if test="${param.id == sessionScope.usuarioId}">
  <c:redirect url="usuarios.jsp?error=propio" />
</c:if>

<%-- Revalidacion 4: no es el unico administrador activo --%>
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
    <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=conexion" />
  </c:if>
  <c:if test="${adm.rows[0].n == 0}">
    <c:redirect url="usuarios.jsp?error=ultimo-admin" />
  </c:if>
</c:if>

<%-- Revalidacion 5: ninguna FK hacia usuarios fuera de las reglas cubiertas --%>
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
<c:if test="${not empty esqError}">
  <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=conexion" />
</c:if>
<c:if test="${esq.rows[0].n > 0}">
  <c:catch var="esqRefError">
    <sql:query var="esqRef" dataSource="${db}">
      SELECT CONCAT(TABLE_NAME, '.', COLUMN_NAME) AS referencia
      FROM information_schema.KEY_COLUMN_USAGE
      WHERE TABLE_SCHEMA = DATABASE() AND REFERENCED_TABLE_NAME = 'usuarios'
        AND CONCAT(TABLE_NAME, '.', COLUMN_NAME) NOT IN (
          'anteproyectos.estudiante_id', 'anteproyectos.estudiante2_id',
          'anteproyectos.director_id', 'anteproyectos.evaluador_id',
          'ideas.propuesta_por', 'entregas.enviado_por',
          'revisiones.director_id', 'evaluaciones.evaluador_id',
          'avales.coordinador_id')
      ORDER BY TABLE_NAME, COLUMN_NAME LIMIT 1
    </sql:query>
  </c:catch>
  <c:choose>
    <c:when test="${empty esqRefError and not empty esqRef.rows}">
      <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=nocubierta&tabla=${esqRef.rows[0].referencia}" />
    </c:when>
    <c:otherwise>
      <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=nocubierta" />
    </c:otherwise>
  </c:choose>
</c:if>

<%-- Relaciones actuales del usuario --%>
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
<c:if test="${not empty relError}">
  <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=conexion" />
</c:if>
<c:set var="relTotal" value="${rel.rows[0].n_est + rel.rows[0].n_est2 + rel.rows[0].n_dir + rel.rows[0].n_eva + rel.rows[0].n_ideas + rel.rows[0].n_entregas + rel.rows[0].n_rev + rel.rows[0].n_eval + rel.rows[0].n_ava}" />

<%-- Revalidacion 6: heredero valido cuando aplica --%>
<c:set var="requiereHeredero" value="${relTotal > 0 and (usr.rows[0].rol == 'PROFESOR' or usr.rows[0].rol == 'COORDINACION' or usr.rows[0].rol == 'ADMINISTRADOR')}" />
<c:if test="${requiereHeredero}">
  <c:set var="herederoOk" value="${false}" />
  <c:if test="${not empty param.heredero_id and param.heredero_id != param.id}">
    <c:choose>
      <c:when test="${usr.rows[0].rol == 'PROFESOR'}">
        <c:catch var="herError">
          <sql:query var="her" dataSource="${db}">
            SELECT COUNT(*) AS n FROM usuarios u
            JOIN roles r ON r.id = u.rol_id
            WHERE u.id = ? AND r.nombre = 'PROFESOR' AND u.estado = 'ACTIVO' AND u.id <> ?
              AND NOT EXISTS (
                SELECT 1 FROM anteproyectos a
                WHERE (a.director_id = ? AND a.evaluador_id = u.id)
                   OR (a.evaluador_id = ? AND a.director_id = u.id))
            <sql:param value="${param.heredero_id}" />
            <sql:param value="${param.id}" />
            <sql:param value="${param.id}" />
            <sql:param value="${param.id}" />
          </sql:query>
        </c:catch>
      </c:when>
      <c:otherwise>
        <c:catch var="herError">
          <sql:query var="her" dataSource="${db}">
            SELECT COUNT(*) AS n FROM usuarios u
            JOIN roles r ON r.id = u.rol_id
            WHERE u.id = ? AND (r.nombre = 'COORDINACION' OR r.nombre = 'ADMINISTRADOR') AND u.estado = 'ACTIVO' AND u.id <> ?
            <sql:param value="${param.heredero_id}" />
            <sql:param value="${param.id}" />
          </sql:query>
        </c:catch>
      </c:otherwise>
    </c:choose>
    <c:if test="${not empty herError}">
      <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=conexion" />
    </c:if>
    <c:if test="${not empty her and her.rows[0].n == 1}">
      <c:set var="herederoOk" value="${true}" />
    </c:if>
  </c:if>
  <c:if test="${not herederoOk}">
    <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=heredero" />
  </c:if>
</c:if>

<%-- Revalidacion extra (ESTUDIANTE): relaciones residuales que las reglas no cubren --%>
<c:if test="${usr.rows[0].rol == 'ESTUDIANTE'}">
  <c:catch var="chkEntError">
    <sql:query var="chkEnt" dataSource="${db}">
      SELECT COUNT(*) AS n FROM entregas e
      WHERE e.enviado_por = ?
        AND NOT EXISTS (
          SELECT 1 FROM anteproyectos a
          WHERE a.id = e.anteproyecto_id
            AND (a.estudiante_id = ? OR a.estudiante2_id = ?))
      <sql:param value="${param.id}" />
      <sql:param value="${param.id}" />
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${empty chkEntError and chkEnt.rows[0].n > 0}">
    <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=residual&tabla=entregas" />
  </c:if>

  <c:catch var="chkRevError">
    <sql:query var="chkRev" dataSource="${db}">
      SELECT COUNT(*) AS n FROM revisiones WHERE director_id = ?
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${empty chkRevError and chkRev.rows[0].n > 0}">
    <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=residual&tabla=revisiones" />
  </c:if>

  <c:catch var="chkEvaError">
    <sql:query var="chkEva" dataSource="${db}">
      SELECT COUNT(*) AS n FROM evaluaciones WHERE evaluador_id = ?
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${empty chkEvaError and chkEva.rows[0].n > 0}">
    <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=residual&tabla=evaluaciones" />
  </c:if>

  <c:catch var="chkAvaError">
    <sql:query var="chkAva" dataSource="${db}">
      SELECT COUNT(*) AS n FROM avales WHERE coordinador_id = ?
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${empty chkAvaError and chkAva.rows[0].n > 0}">
    <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=residual&tabla=avales" />
  </c:if>

  <c:catch var="chkDirError">
    <sql:query var="chkDir" dataSource="${db}">
      SELECT COUNT(*) AS n FROM anteproyectos WHERE director_id = ? OR evaluador_id = ?
      <sql:param value="${param.id}" />
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${empty chkDirError and chkDir.rows[0].n > 0}">
    <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=residual&tabla=anteproyectos" />
  </c:if>

  <c:catch var="chkIdeaError">
    <sql:query var="chkIdea" dataSource="${db}">
      SELECT COUNT(*) AS n FROM ideas i
      WHERE i.propuesta_por = ?
        AND EXISTS (
          SELECT 1 FROM anteproyectos a
          WHERE (a.idea_id = i.id OR a.idea_solicitada_id = i.id)
            AND (a.estudiante_id IS NULL OR a.estudiante_id <> ?))
      <sql:param value="${param.id}" />
      <sql:param value="${param.id}" />
    </sql:query>
  </c:catch>
  <c:if test="${empty chkIdeaError and chkIdea.rows[0].n > 0}">
    <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=heredero&motivo=estudiante" />
  </c:if>

  <c:if test="${not empty chkEntError or not empty chkRevError or not empty chkEvaError or not empty chkAvaError or not empty chkDirError or not empty chkIdeaError}">
    <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=conexion" />
  </c:if>
</c:if>

<%-- Una sola transaccion: si algo falla se revierte todo --%>
<c:set var="movidos" value="${0}" />
<c:set var="borrados" value="${0}" />
<c:catch var="txError">
  <sql:transaction dataSource="${db}">
    <c:choose>
      <c:when test="${usr.rows[0].rol == 'ESTUDIANTE'}">

        <%-- Proyectos como principal CON companero: el companero pasa a principal --%>
        <sql:query var="proyComp">
          SELECT a.id, a.estudiante2_id, a.idea_id, a.idea_solicitada_id
          FROM anteproyectos a
          WHERE a.estudiante_id = ? AND a.estudiante2_id IS NOT NULL
          ORDER BY a.id
          <sql:param value="${param.id}" />
        </sql:query>
        <c:forEach var="pc" items="${proyComp.rows}">
          <sql:update var="t1">
            UPDATE entregas SET enviado_por = ?
            WHERE anteproyecto_id = ? AND enviado_por = ?
            <sql:param value="${pc.estudiante2_id}" />
            <sql:param value="${pc.id}" />
            <sql:param value="${param.id}" />
          </sql:update>
          <c:set var="movidos" value="${movidos + t1}" />
          <sql:update var="t2">
            UPDATE ideas SET propuesta_por = ?
            WHERE propuesta_por = ?
              AND id IN (
                SELECT a2.idea_id FROM anteproyectos a2 WHERE a2.id = ?
                UNION
                SELECT a3.idea_solicitada_id FROM anteproyectos a3 WHERE a3.id = ?)
            <sql:param value="${pc.estudiante2_id}" />
            <sql:param value="${param.id}" />
            <sql:param value="${pc.id}" />
            <sql:param value="${pc.id}" />
          </sql:update>
          <c:set var="movidos" value="${movidos + t2}" />
          <sql:update var="t3">
            UPDATE anteproyectos SET estudiante_id = estudiante2_id, estudiante2_id = NULL
            WHERE id = ?
            <sql:param value="${pc.id}" />
          </sql:update>
          <c:set var="movidos" value="${movidos + t3}" />
        </c:forEach>

        <%-- Proyectos como principal SIN companero: se elimina el proyecto y sus registros --%>
        <sql:query var="proySolos">
          SELECT a.id, a.idea_id, a.idea_solicitada_id
          FROM anteproyectos a
          WHERE a.estudiante_id = ? AND a.estudiante2_id IS NULL
          ORDER BY a.id
          <sql:param value="${param.id}" />
        </sql:query>
        <c:forEach var="ps" items="${proySolos.rows}">
          <sql:update var="dAva">
            DELETE FROM avales WHERE anteproyecto_id = ?
            <sql:param value="${ps.id}" />
          </sql:update>
          <sql:update var="dEva">
            DELETE FROM evaluaciones WHERE anteproyecto_id = ?
            <sql:param value="${ps.id}" />
          </sql:update>
          <sql:update var="dRev">
            DELETE FROM revisiones WHERE anteproyecto_id = ?
            <sql:param value="${ps.id}" />
          </sql:update>
          <sql:update var="dEnt">
            DELETE FROM entregas WHERE anteproyecto_id = ?
            <sql:param value="${ps.id}" />
          </sql:update>
          <sql:update var="dPro">
            DELETE FROM anteproyectos WHERE id = ?
            <sql:param value="${ps.id}" />
          </sql:update>
          <c:set var="borrados" value="${borrados + dPro}" />

          <%-- La idea del proyecto (idea_id): si era del usuario se elimina; si es del
               banco y quedo sin proyecto, vuelve a DISPONIBLE --%>
          <c:if test="${not empty ps.idea_id}">
            <sql:update var="ideaDelA">
              DELETE FROM ideas
              WHERE id = ? AND propuesta_por = ? AND estado IN ('POSTULADA', 'ASIGNADA')
                AND id NOT IN (
                  SELECT a4.idea_id FROM anteproyectos a4 WHERE a4.idea_id IS NOT NULL
                  UNION
                  SELECT a5.idea_solicitada_id FROM anteproyectos a5 WHERE a5.idea_solicitada_id IS NOT NULL)
              <sql:param value="${ps.idea_id}" />
              <sql:param value="${param.id}" />
            </sql:update>
            <sql:update var="ideaLibreA">
              UPDATE ideas SET estado = 'DISPONIBLE'
              WHERE id = ? AND estado = 'ASIGNADA'
                AND (propuesta_por IS NULL OR propuesta_por <> ?)
                AND id NOT IN (
                  SELECT a6.idea_id FROM anteproyectos a6 WHERE a6.idea_id IS NOT NULL
                  UNION
                  SELECT a7.idea_solicitada_id FROM anteproyectos a7 WHERE a7.idea_solicitada_id IS NOT NULL)
              <sql:param value="${ps.idea_id}" />
              <sql:param value="${param.id}" />
            </sql:update>
          </c:if>
          <%-- La idea solicitada (idea_solicitada_id): misma regla --%>
          <c:if test="${not empty ps.idea_solicitada_id}">
            <sql:update var="ideaDelB">
              DELETE FROM ideas
              WHERE id = ? AND propuesta_por = ? AND estado IN ('POSTULADA', 'ASIGNADA')
                AND id NOT IN (
                  SELECT a8.idea_id FROM anteproyectos a8 WHERE a8.idea_id IS NOT NULL
                  UNION
                  SELECT a9.idea_solicitada_id FROM anteproyectos a9 WHERE a9.idea_solicitada_id IS NOT NULL)
              <sql:param value="${ps.idea_solicitada_id}" />
              <sql:param value="${param.id}" />
            </sql:update>
            <sql:update var="ideaLibreB">
              UPDATE ideas SET estado = 'DISPONIBLE'
              WHERE id = ? AND estado = 'ASIGNADA'
                AND (propuesta_por IS NULL OR propuesta_por <> ?)
                AND id NOT IN (
                  SELECT a10.idea_id FROM anteproyectos a10 WHERE a10.idea_id IS NOT NULL
                  UNION
                  SELECT a11.idea_solicitada_id FROM anteproyectos a11 WHERE a11.idea_solicitada_id IS NOT NULL)
              <sql:param value="${ps.idea_solicitada_id}" />
              <sql:param value="${param.id}" />
            </sql:update>
          </c:if>
        </c:forEach>

        <%-- Proyectos como companero: sale del equipo y sus enlaces pasan al principal --%>
        <sql:query var="proyComoComp">
          SELECT a.id, a.estudiante_id
          FROM anteproyectos a
          WHERE a.estudiante2_id = ?
          ORDER BY a.id
          <sql:param value="${param.id}" />
        </sql:query>
        <c:forEach var="pk" items="${proyComoComp.rows}">
          <sql:update var="t4">
            UPDATE entregas SET enviado_por = ?
            WHERE anteproyecto_id = ? AND enviado_por = ?
            <sql:param value="${pk.estudiante_id}" />
            <sql:param value="${pk.id}" />
            <sql:param value="${param.id}" />
          </sql:update>
          <c:set var="movidos" value="${movidos + t4}" />
          <sql:update var="t5">
            UPDATE anteproyectos SET estudiante2_id = NULL WHERE id = ?
            <sql:param value="${pk.id}" />
          </sql:update>
          <c:set var="movidos" value="${movidos + t5}" />
        </c:forEach>

        <%-- Ideas restantes sin proyecto: se eliminan --%>
        <sql:update var="t6">
          DELETE FROM ideas
          WHERE propuesta_por = ?
            AND id NOT IN (
              SELECT a12.idea_id FROM anteproyectos a12 WHERE a12.idea_id IS NOT NULL
              UNION
              SELECT a13.idea_solicitada_id FROM anteproyectos a13 WHERE a13.idea_solicitada_id IS NOT NULL)
          <sql:param value="${param.id}" />
        </sql:update>

      </c:when>
      <c:otherwise>
        <%-- PROFESOR / COORDINACION / ADMINISTRADOR: transferir TODAS las relaciones --%>
        <sql:update var="m1">
          UPDATE anteproyectos SET director_id = ? WHERE director_id = ?
          <sql:param value="${param.heredero_id}" />
          <sql:param value="${param.id}" />
        </sql:update>
        <c:set var="movidos" value="${movidos + m1}" />
        <sql:update var="m2">
          UPDATE anteproyectos SET evaluador_id = ? WHERE evaluador_id = ?
          <sql:param value="${param.heredero_id}" />
          <sql:param value="${param.id}" />
        </sql:update>
        <c:set var="movidos" value="${movidos + m2}" />
        <sql:update var="m3">
          UPDATE revisiones SET director_id = ? WHERE director_id = ?
          <sql:param value="${param.heredero_id}" />
          <sql:param value="${param.id}" />
        </sql:update>
        <c:set var="movidos" value="${movidos + m3}" />
        <sql:update var="m4">
          UPDATE evaluaciones SET evaluador_id = ? WHERE evaluador_id = ?
          <sql:param value="${param.heredero_id}" />
          <sql:param value="${param.id}" />
        </sql:update>
        <c:set var="movidos" value="${movidos + m4}" />
        <sql:update var="m5">
          UPDATE entregas SET enviado_por = ? WHERE enviado_por = ?
          <sql:param value="${param.heredero_id}" />
          <sql:param value="${param.id}" />
        </sql:update>
        <c:set var="movidos" value="${movidos + m5}" />
        <sql:update var="m6">
          UPDATE avales SET coordinador_id = ? WHERE coordinador_id = ?
          <sql:param value="${param.heredero_id}" />
          <sql:param value="${param.id}" />
        </sql:update>
        <c:set var="movidos" value="${movidos + m6}" />
        <sql:update var="m7">
          UPDATE ideas SET propuesta_por = ? WHERE propuesta_por = ?
          <sql:param value="${param.heredero_id}" />
          <sql:param value="${param.id}" />
        </sql:update>
        <c:set var="movidos" value="${movidos + m7}" />
      </c:otherwise>
    </c:choose>

    <%-- Ultimo paso: eliminar el usuario --%>
    <sql:update var="delUsr">
      DELETE FROM usuarios WHERE id = ?
      <sql:param value="${param.id}" />
    </sql:update>
  </sql:transaction>
</c:catch>

<c:choose>
  <c:when test="${empty txError}">
    <c:set var="flashUsuarios" scope="session" value="Usuario eliminado definitivamente. Se eliminaron ${borrados} proyecto(s) y se transfirieron ${movidos} registro(s)." />
    <c:redirect url="usuarios.jsp" />
  </c:when>
  <c:otherwise>
    <c:redirect url="usuario-eliminar-confirmar.jsp?id=${param.id}&error=invalido" />
  </c:otherwise>
</c:choose>
