<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%--
  header.jsp
  Apertura del documento HTML: <head> con Bootstrap 5 + Font Awesome (CDN)
  y css/estilos.css, mas apertura de <body>.
  Las paginas deben definir antes de importar:
    <c:set var="titulo" value="..." scope="request" />
    <c:set var="activo" value="inicio" scope="request" />
  Uso:
    <c:import url="includes/header.jsp" />
    <c:import url="includes/sidebar.jsp" />
      ... contenido ...
    <c:import url="includes/footer.jsp" />
--%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title><c:out value="${requestScope.titulo}" default="Trabajos de Grado" /> | Ingenieria de Sistemas UTS</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet" />
  <link href="css/estilos.css" rel="stylesheet" />
</head>
<body>
