<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%--
  sidebar.jsp
  Abre el layout: <div class="app"> + sidebar blanco + <div class="main">
  con el header superior ("Bienvenido" + nombre de sesion) y abre <main>.
  El menu se filtra por rol con <c:if> usando sessionScope.rol.
  Valores esperados en sesion:
    sessionScope.usuarioNombre, sessionScope.rol
  La pagina define requestScope.activo: inicio|usuarios|perfil|ideas|proyectos|informes|calendario|practicas|documental
--%>
<div class="app">

  <aside class="sidebar">
    <div class="brand">
      <div class="brand-logo"><i class="fa-solid fa-graduation-cap"></i></div>
      <div class="brand-text">
        <strong>Ingenieria de Sistemas</strong>
        <span>UTS</span>
      </div>
    </div>

    <nav class="menu">

      <%-- Inicio: visible para todos (incluye visitante de prueba) --%>
      <a href="index.jsp" class="menu-item ${requestScope.activo == 'inicio' ? 'active' : ''}">
        <i class="fa-solid fa-house"></i> Inicio
      </a>

      <%-- Usuarios: solo ADMINISTRADOR --%>
      <c:if test="${sessionScope.rol == 'ADMINISTRADOR'}">
        <a href="usuarios.jsp" class="menu-item ${requestScope.activo == 'usuarios' ? 'active' : ''}">
          <i class="fa-solid fa-users"></i> Usuarios
        </a>
      </c:if>

      <%-- Mi perfil: solo usuarios en sesion --%>
      <c:if test="${not empty sessionScope.rol}">
        <a href="perfil.jsp" class="menu-item ${requestScope.activo == 'perfil' ? 'active' : ''}">
          <i class="fa-solid fa-user"></i> Mi perfil
        </a>
      </c:if>

      <%-- Banco de ideas: ESTUDIANTE, PROFESOR, COORDINACION, ADMINISTRADOR --%>
      <c:if test="${sessionScope.rol == 'ESTUDIANTE' or sessionScope.rol == 'PROFESOR' or sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR'}">
        <a href="ideas.jsp" class="menu-item ${requestScope.activo == 'ideas' ? 'active' : ''}">
          <i class="fa-solid fa-lightbulb"></i> Banco de ideas
        </a>
      </c:if>

      <%-- Mis proyectos: ESTUDIANTE, PROFESOR, COORDINACION, ADMINISTRADOR --%>
      <c:if test="${sessionScope.rol == 'ESTUDIANTE' or sessionScope.rol == 'PROFESOR' or sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR'}">
        <a href="mis-proyectos.jsp" class="menu-item ${requestScope.activo == 'proyectos' ? 'active' : ''}">
          <i class="fa-solid fa-diagram-project"></i> Mis proyectos
        </a>
      </c:if>

      <%-- Informes: solo COORDINACION y ADMINISTRADOR --%>
      <c:if test="${sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR'}">
        <a href="informes.jsp" class="menu-item ${requestScope.activo == 'informes' ? 'active' : ''}">
          <i class="fa-solid fa-chart-column"></i> Informes
        </a>
      </c:if>

      <%-- Mis practicas: ESTUDIANTE, COORDINACION, ADMINISTRADOR --%>
      <c:if test="${sessionScope.rol == 'ESTUDIANTE' or sessionScope.rol == 'COORDINACION' or sessionScope.rol == 'ADMINISTRADOR'}">
        <a href="practicas.jsp" class="menu-item ${requestScope.activo == 'practicas' ? 'active' : ''}">
          <i class="fa-solid fa-briefcase"></i> Mis pr&aacute;cticas
        </a>
      </c:if>

      <%-- Base documental: visible para todos --%>
      <a href="formatos.jsp" class="menu-item ${requestScope.activo == 'documental' ? 'active' : ''}">
        <i class="fa-solid fa-folder-open"></i> Base documental
      </a>

      <%-- Calendario: todos los roles autenticados --%>
      <c:if test="${not empty sessionScope.rol}">
        <a href="calendario.jsp" class="menu-item ${requestScope.activo == 'calendario' ? 'active' : ''}">
          <i class="fa-solid fa-calendar-days"></i> Calendario
        </a>
      </c:if>

    </nav>

    <div class="sidebar-foot">
      <c:if test="${not empty sessionScope.rol}">
        <span class="rol-badge"><c:out value="${sessionScope.rol}" /></span>
      </c:if>
      <c:if test="${empty sessionScope.rol}">
        <span class="rol-badge rol-invitado">MODO PRUEBA</span>
      </c:if>
    </div>
  </aside>

  <div class="main">
    <header class="topbar">
      <div class="topbar-title">
        <strong><c:out value="${requestScope.titulo}" default="Inicio" /></strong>
      </div>
      <div class="topbar-user dropdown">
        <span class="bienvenido">Bienvenido</span>
        <a href="#" class="username dropdown-toggle" role="button" data-bs-toggle="dropdown" aria-expanded="false">
          <i class="fa-solid fa-circle-user"></i>
          <c:out value="${sessionScope.usuarioNombre}" default="Invitado" />
        </a>
        <ul class="dropdown-menu dropdown-menu-end">
          <c:if test="${not empty sessionScope.usuarioId}">
            <li><a class="dropdown-item" href="perfil.jsp"><i class="fa-solid fa-user"></i> Mi perfil</a></li>
            <li><a class="dropdown-item" href="logout.jsp"><i class="fa-solid fa-right-from-bracket"></i> Cerrar sesi&oacute;n</a></li>
          </c:if>
          <c:if test="${empty sessionScope.usuarioId}">
            <li><a class="dropdown-item" href="login.jsp"><i class="fa-solid fa-right-to-bracket"></i> Iniciar sesi&oacute;n</a></li>
          </c:if>
        </ul>
      </div>
    </header>

    <main class="contenido">
