<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%--
  login.jsp
  Muestra el formulario y valida el POST en la misma pagina, solo con JSTL.
  Exito: guarda usuarioId, usuarioNombre y rol en sesion y redirige a index.jsp.
  Fallo: muestra alerta roja. Solo entran usuarios con estado ACTIVO.
--%>
<c:import url="includes/conexion.jsp" />
<c:if test="${pageContext.request.method == 'GET' and not empty sessionScope.usuarioId}">
  <c:redirect url="index.jsp" />
</c:if>
<c:if test="${pageContext.request.method == 'POST'}">
  <c:catch var="dbError">
    <sql:query var="loginOk" dataSource="${db}">
      SELECT u.id AS id, u.nombre AS nombre,
             (SELECT r.nombre FROM roles r WHERE r.id = u.rol_id) AS rol
      FROM usuarios u
      WHERE u.correo = ? AND u.password = SHA2(?, 256) AND u.estado = 'ACTIVO'
      <sql:param value="${param.correo}" />
      <sql:param value="${param.password}" />
    </sql:query>
  </c:catch>
  <c:choose>
    <c:when test="${not empty dbError}">
      <c:set var="loginError" value="Error de conexión. Intente de nuevo." scope="request" />
    </c:when>
    <c:when test="${loginOk.rowCount == 1}">
      <c:set var="usuarioId" value="${loginOk.rows[0].id}" scope="session" />
      <c:set var="usuarioNombre" value="${loginOk.rows[0].nombre}" scope="session" />
      <c:set var="rol" value="${loginOk.rows[0].rol}" scope="session" />
      <c:redirect url="index.jsp" />
    </c:when>
    <c:otherwise>
      <c:set var="loginError" value="Correo o contraseña incorrectos." scope="request" />
    </c:otherwise>
  </c:choose>
</c:if>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Iniciar sesi&oacute;n | Ingenieria de Sistemas UTS</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet" />
  <link href="css/estilos.css" rel="stylesheet" />
</head>
<body class="login-page">

  <div class="login-wrap">
    <div class="login-logo">
      <div class="brand-logo"><i class="fa-solid fa-graduation-cap"></i></div>
      <div>
        <strong>Ingenier&iacute;a de Sistemas</strong>
        <span>UTS</span>
      </div>
    </div>

    <div class="card login-card">
      <div class="card-body">
        <h5 class="login-title">Iniciar <span class="badge-sesion">SESI&Oacute;N</span></h5>

        <c:if test="${not empty requestScope.loginError}">
          <div class="alert alert-danger py-2" role="alert">
            <c:out value="${requestScope.loginError}" />
          </div>
        </c:if>

        <form method="post" action="login.jsp">
          <label class="form-label" for="correo">Correo</label>
          <div class="input-group mb-3">
            <span class="input-group-text"><i class="fa-solid fa-envelope"></i></span>
            <input type="email" class="form-control" id="correo" name="correo" required="required"
                   placeholder="Ingrese su correo institucional." value="${fn:escapeXml(param.correo)}" />
          </div>

          <label class="form-label" for="password">Contrase&ntilde;a</label>
          <div class="input-group mb-3">
            <span class="input-group-text"><i class="fa-solid fa-lock"></i></span>
            <input type="password" class="form-control" id="password" name="password" required="required"
                   placeholder="Ingrese su contrase&ntilde;a." />
          </div>

          <div class="form-check mb-3">
            <input class="form-check-input" type="checkbox" id="recordar" name="recordar" value="1" />
            <label class="form-check-label" for="recordar">Mantener sesi&oacute;n activa</label>
          </div>

          <button type="submit" class="btn btn-lima w-100">ENVIAR</button>
        </form>
      </div>
    </div>

    <div class="login-links">
      <a href="bienvenida.jsp" class="text-decoration-none text-secondary fw-semibold">
        <i class="fa-solid fa-arrow-left"></i> Volver al inicio
      </a>
    </div>
  </div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
