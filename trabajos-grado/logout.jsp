<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%--
  logout.jsp
  Exige sesión (guard) para cumplir la regla de protección global,
  la invalida (remueve las variables) y redirige a login.jsp.
  Sin salida HTML antes del redirect.
--%>
<%@ include file="includes/guard.jspf" %>
<c:remove var="usuarioId" scope="session" />
<c:remove var="usuarioNombre" scope="session" />
<c:remove var="rol" scope="session" />
<c:redirect url="login.jsp" />
