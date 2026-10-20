<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%--
  bienvenida.jsp
  Pagina de aterrizaje publica del sistema (no consulta la base de datos).
  Si ya hay una sesion activa redirige al tablero (index.jsp).
  El boton principal lleva al inicio de sesion existente (login.jsp).
  Es el archivo de bienvenida declarado en WEB-INF/web.xml.
--%>
<c:if test="${not empty sessionScope.usuarioId}">
  <c:redirect url="index.jsp" />
</c:if>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="description" content="Plataforma academica para gestionar ideas, anteproyectos, entregas, revisiones y evaluaciones del trabajo de grado. Ingenieria de Sistemas UTS." />
  <meta name="theme-color" content="#20241a" />
  <title>Sistema de Trabajos de Grado | Ingenier&iacute;a de Sistemas UTS</title>

  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet" />
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet" />
  <link href="css/estilos.css" rel="stylesheet" />

  <style>
    :root {
      --lima: #BFD730;
      --lima-oscuro: #9DB324;
      --lima-suave: #eef5c9;
      --tinta: #20241a;
      --carbon: #2f3336;
      --gris: #5b6268;
      --gris-claro: #8a9086;
      --linea: #e4e8da;
      --fondo: #f7f8f3;
      --blanco: #ffffff;
      --radio: 18px;
      --sombra: 0 18px 40px rgba(32, 36, 26, .10);
    }

    html { scroll-behavior: smooth; }

    body.landing {
      font-family: "Plus Jakarta Sans", "Segoe UI", system-ui, -apple-system, sans-serif;
      background: var(--fondo);
      color: var(--tinta);
      -webkit-font-smoothing: antialiased;
    }
    body.landing [id] { scroll-margin-top: 92px; }

    /* ===== Barra superior ===== */
    .ld-nav {
      position: sticky;
      top: 0;
      z-index: 100;
      background: rgba(247, 248, 243, .86);
      -webkit-backdrop-filter: blur(12px);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--linea);
    }
    .ld-nav-inner {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1.25rem;
      padding: .7rem 0;
    }
    .ld-brand {
      display: flex;
      align-items: center;
      gap: .65rem;
      text-decoration: none;
      color: inherit;
    }
    .ld-brand .brand-logo {
      width: 42px;
      height: 42px;
      border-radius: 12px;
      font-size: 1.2rem;
    }
    .ld-brand-text strong {
      display: block;
      font-size: .95rem;
      line-height: 1.15;
      letter-spacing: -.2px;
    }
    .ld-brand-text span {
      font-size: .68rem;
      letter-spacing: 2.5px;
      color: var(--gris-claro);
      font-weight: 600;
    }
    .ld-links { display: flex; gap: 1.75rem; }
    .ld-links a {
      color: var(--carbon);
      text-decoration: none;
      font-weight: 600;
      font-size: .92rem;
      padding: .25rem 0;
      border-bottom: 2px solid transparent;
      transition: color .15s, border-color .15s;
    }
    .ld-links a:hover { color: #6d7d12; border-color: var(--lima); }
    .btn.ld-btn-login {
      display: inline-flex;
      align-items: center;
      gap: .5rem;
      padding: .55rem 1.1rem;
      font-size: .9rem;
      border-radius: 11px;
    }

    /* ===== Hero ===== */
    .ld-hero { position: relative; overflow: hidden; padding: 4.2rem 0 3.9rem; }
    .ld-hero::before {
      content: "";
      position: absolute;
      inset: 0;
      pointer-events: none;
      background:
        radial-gradient(720px 420px at 88% 0%, rgba(191, 215, 48, .30), transparent 65%),
        radial-gradient(560px 380px at 0% 100%, rgba(191, 215, 48, .14), transparent 65%);
    }
    .ld-hero::after {
      content: "";
      position: absolute;
      inset: 0;
      pointer-events: none;
      opacity: .35;
      background-image: radial-gradient(rgba(32, 36, 26, .10) 1px, transparent 1px);
      background-size: 26px 26px;
      -webkit-mask-image: linear-gradient(to bottom, #000 0%, transparent 70%);
      mask-image: linear-gradient(to bottom, #000 0%, transparent 70%);
    }
    .ld-hero .container { position: relative; z-index: 1; }
    .ld-hero-grid {
      display: grid;
      grid-template-columns: 1.04fr .96fr;
      gap: 3.2rem;
      align-items: center;
    }
    .ld-eyebrow {
      display: inline-flex;
      align-items: center;
      gap: .55rem;
      background: #fff;
      border: 1px solid var(--linea);
      border-radius: 999px;
      padding: .38rem .85rem;
      font-size: .72rem;
      font-weight: 800;
      letter-spacing: 1.6px;
      text-transform: uppercase;
      color: #59631b;
      box-shadow: 0 2px 8px rgba(32, 36, 26, .04);
    }
    .ld-pulse {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--lima);
      box-shadow: 0 0 0 4px rgba(191, 215, 48, .22);
    }
    .ld-title {
      font-size: clamp(2.25rem, 4.4vw, 3.55rem);
      font-weight: 800;
      line-height: 1.06;
      letter-spacing: -2px;
      margin: 1.1rem 0 1rem;
    }
    .ld-highlight {
      background: linear-gradient(transparent 64%, rgba(191, 215, 48, .62) 64%, rgba(191, 215, 48, .62) 92%, transparent 92%);
    }
    .ld-sub {
      font-size: 1.06rem;
      color: var(--gris);
      max-width: 34rem;
      line-height: 1.65;
      margin-bottom: 1.6rem;
    }
    .ld-actions { display: flex; flex-wrap: wrap; align-items: center; gap: .8rem; }
    .btn.ld-btn-hero {
      display: inline-flex;
      align-items: center;
      gap: .6rem;
      padding: .95rem 1.55rem;
      font-size: 1rem;
      border-radius: 12px;
      letter-spacing: .2px;
      box-shadow: 0 12px 26px rgba(157, 179, 36, .35);
      transition: transform .15s, box-shadow .15s;
    }
    .btn.ld-btn-hero:hover { transform: translateY(-1px); box-shadow: 0 16px 30px rgba(157, 179, 36, .42); }
    .ld-btn-ghost {
      display: inline-flex;
      align-items: center;
      gap: .5rem;
      padding: .9rem 1.4rem;
      border-radius: 12px;
      background: #fff;
      border: 1px solid var(--linea);
      color: var(--tinta);
      font-weight: 700;
      font-size: .98rem;
      text-decoration: none;
      transition: border-color .15s, box-shadow .15s;
    }
    .ld-btn-ghost:hover { border-color: var(--lima-oscuro); box-shadow: 0 8px 18px rgba(32, 36, 26, .06); color: var(--tinta); }
    .ld-note {
      display: flex;
      align-items: center;
      gap: .5rem;
      margin: 1.1rem 0 0;
      font-size: .85rem;
      color: var(--gris-claro);
    }
    .ld-note i { color: var(--lima-oscuro); }

    /* ===== Vista previa del panel ===== */
    .ld-preview-wrap { position: relative; padding: 1.1rem; }
    .ld-window {
      background: #fff;
      border: 1px solid var(--linea);
      border-radius: 22px;
      box-shadow: var(--sombra);
      overflow: hidden;
      transform: rotate(-.8deg);
      transition: transform .3s;
    }
    .ld-preview-wrap:hover .ld-window { transform: rotate(0) translateY(-3px); }
    .ld-top {
      display: flex;
      align-items: center;
      gap: .42rem;
      background: #f2f4ec;
      border-bottom: 1px solid var(--linea);
      padding: .7rem .95rem;
    }
    .ld-dot { width: 9px; height: 9px; border-radius: 50%; background: #d8dccd; }
    .ld-dot.d1 { background: #e8887f; }
    .ld-dot.d2 { background: #ecc766; }
    .ld-dot.d3 { background: #a9cb55; }
    .ld-url {
      margin-left: .55rem;
      font-size: .7rem;
      color: var(--gris-claro);
      background: #fff;
      border: 1px solid var(--linea);
      padding: .16rem .65rem;
      border-radius: 999px;
    }
    .ld-win-body { padding: 1.3rem; }
    .ld-win-head { display: flex; justify-content: space-between; align-items: flex-start; gap: .8rem; }
    .ld-pv-kicker {
      display: block;
      font-size: .64rem;
      letter-spacing: 1.8px;
      text-transform: uppercase;
      color: var(--gris-claro);
      font-weight: 800;
      margin-bottom: .15rem;
    }
    .ld-win-head strong { font-size: 1.02rem; letter-spacing: -.2px; }
    .ld-badge {
      background: var(--lima-suave);
      color: #4d5c0a;
      font-size: .7rem;
      font-weight: 800;
      padding: .3rem .65rem;
      border-radius: 999px;
      white-space: nowrap;
    }
    .ld-progress { margin: 1.15rem 0; }
    .ld-progress-label { display: flex; justify-content: space-between; font-size: .78rem; color: var(--gris); margin-bottom: .45rem; }
    .ld-progress-label strong { color: var(--tinta); }
    .ld-bar { height: 9px; border-radius: 999px; background: #edf0e3; overflow: hidden; }
    .ld-bar span {
      display: block;
      height: 100%;
      width: 60%;
      border-radius: 999px;
      background: linear-gradient(90deg, var(--lima-oscuro), var(--lima));
    }
    .ld-fases { list-style: none; display: flex; flex-wrap: wrap; gap: .42rem; margin: 0 0 1.15rem; padding: 0; }
    .ld-fases li {
      display: inline-flex;
      align-items: center;
      gap: .35rem;
      font-size: .7rem;
      font-weight: 700;
      color: #7b8273;
      background: #f3f5ec;
      border-radius: 999px;
      padding: .32rem .6rem;
    }
    .ld-fases li.ok { background: var(--lima-suave); color: #4d5c0a; }
    .ld-fases li.act { background: var(--tinta); color: #fff; }
    .ld-mini-grid { display: grid; grid-template-columns: 1fr 1fr; gap: .55rem; }
    .ld-mini {
      display: flex;
      align-items: center;
      gap: .55rem;
      border: 1px solid var(--linea);
      border-radius: 12px;
      padding: .55rem .65rem;
      background: #fcfdf9;
    }
    .ld-mini i { color: var(--lima-oscuro); font-size: .95rem; }
    .ld-mini span {
      display: block;
      font-size: .6rem;
      letter-spacing: 1px;
      text-transform: uppercase;
      color: var(--gris-claro);
      font-weight: 800;
    }
    .ld-mini strong { font-size: .76rem; }
    .ld-float {
      position: absolute;
      display: inline-flex;
      align-items: center;
      gap: .5rem;
      background: #fff;
      border: 1px solid var(--linea);
      border-radius: 12px;
      padding: .55rem .8rem;
      font-size: .76rem;
      font-weight: 800;
      color: var(--tinta);
      box-shadow: 0 14px 28px rgba(32, 36, 26, .14);
      animation: ld-float 5.5s ease-in-out infinite;
    }
    .ld-float i { color: var(--lima-oscuro); }
    .ld-float.f1 { top: 0; right: -4px; }
    .ld-float.f2 { bottom: 2px; left: -8px; animation-delay: 1.4s; }
    @keyframes ld-float {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-8px); }
    }

    /* ===== Tira de modulos ===== */
    .ld-strip { background: #fff; border-top: 1px solid var(--linea); border-bottom: 1px solid var(--linea); }
    .ld-strip-inner {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: center;
      gap: .6rem 1.4rem;
      padding: 1.05rem 0;
    }
    .ld-mod {
      display: inline-flex;
      align-items: center;
      gap: .5rem;
      font-size: .82rem;
      font-weight: 700;
      color: var(--gris);
    }
    .ld-mod::before {
      content: "";
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: var(--lima);
    }

    /* ===== Secciones ===== */
    .ld-section { padding: 4.6rem 0; }
    .ld-section-alt { background: #fff; border-top: 1px solid var(--linea); border-bottom: 1px solid var(--linea); }
    .ld-section-head { max-width: 44rem; margin: 0 auto 2.6rem; text-align: center; }
    .ld-kicker {
      display: inline-block;
      font-size: .72rem;
      font-weight: 800;
      letter-spacing: 2.4px;
      text-transform: uppercase;
      color: #6d7d12;
      background: var(--lima-suave);
      border-radius: 999px;
      padding: .35rem .8rem;
      margin-bottom: .9rem;
    }
    .ld-section-head h2 {
      font-size: clamp(1.55rem, 2.8vw, 2.2rem);
      font-weight: 800;
      letter-spacing: -1px;
      margin-bottom: .6rem;
    }
    .ld-section-head p { color: var(--gris); margin: 0; font-size: 1rem; }

    /* Funcionalidades */
    .ld-features { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.1rem; }
    .ld-feature {
      background: #fff;
      border: 1px solid var(--linea);
      border-radius: var(--radio);
      padding: 1.55rem 1.45rem;
      transition: transform .2s ease, box-shadow .2s ease, border-color .2s ease;
    }
    .ld-feature:hover { transform: translateY(-4px); box-shadow: 0 18px 34px rgba(32, 36, 26, .08); border-color: #d9e4a5; }
    .ld-feature-icon {
      width: 48px;
      height: 48px;
      border-radius: 14px;
      display: grid;
      place-items: center;
      background: var(--lima-suave);
      color: #55630f;
      font-size: 1.15rem;
      margin-bottom: 1rem;
    }
    .ld-feature h3 { font-size: 1.04rem; font-weight: 800; letter-spacing: -.2px; margin-bottom: .4rem; }
    .ld-feature p { font-size: .9rem; color: var(--gris); margin: 0; line-height: 1.6; }

    /* Como funciona */
    .ld-steps { list-style: none; margin: 0; padding: 0; display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; }
    .ld-step {
      position: relative;
      background: var(--fondo);
      border: 1px solid var(--linea);
      border-radius: var(--radio);
      padding: 1.5rem 1.35rem;
    }
    .ld-step-num {
      display: inline-grid;
      place-items: center;
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: var(--tinta);
      color: var(--lima);
      font-weight: 800;
      font-size: 1rem;
      margin-bottom: .9rem;
    }
    .ld-step h3 { font-size: 1rem; font-weight: 800; margin-bottom: .35rem; }
    .ld-step p { font-size: .88rem; color: var(--gris); margin: 0; line-height: 1.6; }

    /* Llamado final */
    .ld-cta {
      position: relative;
      overflow: hidden;
      background: var(--tinta);
      color: #fff;
      border-radius: 26px;
      padding: 3rem clamp(1.5rem, 4.5vw, 3.4rem);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 2rem;
    }
    .ld-cta::before {
      content: "";
      position: absolute;
      inset: 0;
      pointer-events: none;
      background: radial-gradient(640px 260px at 85% -30%, rgba(191, 215, 48, .35), transparent 65%);
    }
    .ld-cta h2 {
      position: relative;
      font-size: clamp(1.4rem, 2.6vw, 1.95rem);
      font-weight: 800;
      letter-spacing: -.8px;
      margin-bottom: .4rem;
    }
    .ld-cta p { position: relative; color: rgba(255, 255, 255, .72); margin: 0; max-width: 34rem; }
    .ld-cta .btn { position: relative; flex-shrink: 0; }

    /* Pie */
    .ld-footer { padding: 2.2rem 0 2.4rem; }
    .ld-footer-inner {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
      flex-wrap: wrap;
      border-top: 1px solid var(--linea);
      padding-top: 1.6rem;
    }
    .ld-footer-copy { margin: 0; color: var(--gris-claro); font-size: .85rem; }
    .ld-footer-link {
      color: var(--carbon);
      font-weight: 700;
      font-size: .88rem;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: .45rem;
    }
    .ld-footer-link:hover { color: #6d7d12; }

    /* Entrada suave del hero */
    @keyframes ld-up {
      from { opacity: 0; transform: translateY(14px); }
      to { opacity: 1; transform: none; }
    }
    .ld-hero-copy > * { animation: ld-up .6s ease both; }
    .ld-hero-copy > *:nth-child(2) { animation-delay: .08s; }
    .ld-hero-copy > *:nth-child(3) { animation-delay: .16s; }
    .ld-hero-copy > *:nth-child(4) { animation-delay: .24s; }
    .ld-hero-copy > *:nth-child(5) { animation-delay: .32s; }

    /* ===== Responsivo ===== */
    @media (max-width: 991.98px) {
      .ld-links { display: none; }
      .ld-hero-grid { grid-template-columns: 1fr; gap: 3rem; }
      .ld-features { grid-template-columns: repeat(2, 1fr); }
      .ld-steps { grid-template-columns: repeat(2, 1fr); }
    }
    @media (max-width: 639.98px) {
      .ld-hero { padding: 2.7rem 0 2.8rem; }
      .ld-title { letter-spacing: -1.4px; }
      .ld-features { grid-template-columns: 1fr; }
    }
    @media (max-width: 575.98px) {
      .ld-float { display: none; }
      .ld-preview-wrap { padding: .4rem; }
      .ld-steps { grid-template-columns: 1fr; }
      .ld-cta { flex-direction: column; align-items: flex-start; }
    }
    @media (prefers-reduced-motion: reduce) {
      html { scroll-behavior: auto; }
      .ld-float { animation: none; }
      .ld-hero-copy > * { animation: none; }
    }
  </style>
</head>
<body class="landing">

  <!-- Barra superior -->
  <header class="ld-nav">
    <div class="container ld-nav-inner">
      <a class="ld-brand" href="bienvenida.jsp" aria-label="Ingenier&iacute;a de Sistemas UTS - inicio">
        <span class="brand-logo"><i class="fa-solid fa-graduation-cap"></i></span>
        <span class="ld-brand-text">
          <strong>Ingenier&iacute;a de Sistemas</strong>
          <span>UTS</span>
        </span>
      </a>

      <nav class="ld-links" aria-label="Secciones de la p&aacute;gina">
        <a href="#funcionalidades">Funcionalidades</a>
        <a href="#como-funciona">C&oacute;mo funciona</a>
      </nav>

      <a class="btn btn-lima ld-btn-login" href="login.jsp">
        <i class="fa-solid fa-right-to-bracket"></i> Iniciar sesi&oacute;n
      </a>
    </div>
  </header>

  <main>

    <!-- Hero -->
    <section class="ld-hero">
      <div class="container">
        <div class="ld-hero-grid">

          <div class="ld-hero-copy">
            <span class="ld-eyebrow"><span class="ld-pulse"></span> Plataforma acad&eacute;mica &middot; UTS</span>
            <h1 class="ld-title">Tu trabajo de grado, <span class="ld-highlight">organizado de principio a fin.</span></h1>
            <p class="ld-sub">
              Gestiona ideas, anteproyectos, entregas, revisiones y evaluaciones en un solo lugar.
              Un proceso claro para estudiantes, profesores y coordinaci&oacute;n.
            </p>
            <div class="ld-actions">
              <a class="btn btn-lima ld-btn-hero" href="login.jsp">
                <i class="fa-solid fa-right-to-bracket"></i> Iniciar sesi&oacute;n
              </a>
              <a class="ld-btn-ghost" href="#funcionalidades">
                Ver funcionalidades <i class="fa-solid fa-arrow-down"></i>
              </a>
            </div>
            <p class="ld-note"><i class="fa-solid fa-shield-halved"></i> Acceso con credenciales institucionales.</p>
          </div>

          <div class="ld-preview-wrap" aria-hidden="true">
            <div class="ld-window">
              <div class="ld-top">
                <span class="ld-dot d1"></span>
                <span class="ld-dot d2"></span>
                <span class="ld-dot d3"></span>
                <span class="ld-url">panel &middot; trabajos de grado</span>
              </div>
              <div class="ld-win-body">
                <div class="ld-win-head">
                  <div>
                    <span class="ld-pv-kicker">Mi proyecto</span>
                    <strong>Sistema de gesti&oacute;n acad&eacute;mica</strong>
                  </div>
                  <span class="ld-badge">En curso</span>
                </div>

                <div class="ld-progress">
                  <div class="ld-progress-label">
                    <span>Avance del proceso</span>
                    <strong>60%</strong>
                  </div>
                  <div class="ld-bar"><span></span></div>
                </div>

                <ul class="ld-fases">
                  <li class="ok"><i class="fa-solid fa-check"></i> Idea</li>
                  <li class="ok"><i class="fa-solid fa-check"></i> Anteproyecto</li>
                  <li class="ok"><i class="fa-solid fa-check"></i> Aval</li>
                  <li class="act"><i class="fa-solid fa-pen"></i> Desarrollo</li>
                  <li><i class="fa-solid fa-flag-checkered"></i> Sustentaci&oacute;n</li>
                </ul>

                <div class="ld-mini-grid">
                  <div class="ld-mini">
                    <i class="fa-solid fa-calendar-days"></i>
                    <div>
                      <span>Pr&oacute;ximo evento</span>
                      <strong>Revisi&oacute;n de avance</strong>
                    </div>
                  </div>
                  <div class="ld-mini">
                    <i class="fa-solid fa-star"></i>
                    <div>
                      <span>Evaluaci&oacute;n</span>
                      <strong>4.5 / 5.0</strong>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="ld-float f1"><i class="fa-solid fa-circle-check"></i> Entrega recibida</div>
            <div class="ld-float f2"><i class="fa-solid fa-calendar-check"></i> Revisi&oacute;n agendada</div>
          </div>

        </div>
      </div>
    </section>

    <!-- Modulos -->
    <section class="ld-strip" aria-label="M&oacute;dulos del sistema">
      <div class="container ld-strip-inner">
        <span class="ld-mod">Banco de ideas</span>
        <span class="ld-mod">Anteproyectos</span>
        <span class="ld-mod">Entregas</span>
        <span class="ld-mod">Revisiones</span>
        <span class="ld-mod">Avales</span>
        <span class="ld-mod">Evaluaciones</span>
        <span class="ld-mod">Calendario</span>
        <span class="ld-mod">Informes</span>
        <span class="ld-mod">Base documental</span>
      </div>
    </section>

    <!-- Funcionalidades -->
    <section class="ld-section" id="funcionalidades">
      <div class="container">
        <div class="ld-section-head">
          <span class="ld-kicker">Funcionalidades</span>
          <h2>Todo el proceso, en un solo sistema</h2>
          <p>Cada etapa del trabajo de grado queda registrada y trazable.</p>
        </div>

        <div class="ld-features">
          <article class="ld-feature">
            <span class="ld-feature-icon"><i class="fa-solid fa-lightbulb"></i></span>
            <h3>Banco de ideas</h3>
            <p>Prop&oacute;n, explora y postula ideas de proyecto con seguimiento de su estado.</p>
          </article>
          <article class="ld-feature">
            <span class="ld-feature-icon"><i class="fa-solid fa-diagram-project"></i></span>
            <h3>Anteproyectos por fases</h3>
            <p>Registra tu anteproyecto y avanza por cada fase del proceso con sus avales.</p>
          </article>
          <article class="ld-feature">
            <span class="ld-feature-icon"><i class="fa-solid fa-file-arrow-up"></i></span>
            <h3>Entregas y seguimiento</h3>
            <p>Registra tus entregas y revisa el estado de cada fase de tu proyecto.</p>
          </article>
          <article class="ld-feature">
            <span class="ld-feature-icon"><i class="fa-solid fa-clipboard-check"></i></span>
            <h3>Revisiones y avales</h3>
            <p>Los profesores revisan, dejan observaciones y avalan el avance del proyecto.</p>
          </article>
          <article class="ld-feature">
            <span class="ld-feature-icon"><i class="fa-solid fa-star-half-stroke"></i></span>
            <h3>Evaluaciones</h3>
            <p>Eval&uacute;a y consulta los resultados del proceso de sustentaci&oacute;n.</p>
          </article>
          <article class="ld-feature">
            <span class="ld-feature-icon"><i class="fa-solid fa-calendar-days"></i></span>
            <h3>Calendario acad&eacute;mico</h3>
            <p>Consulta las fechas clave y los eventos del programa, mes a mes.</p>
          </article>
        </div>
      </div>
    </section>

    <!-- Como funciona -->
    <section class="ld-section ld-section-alt" id="como-funciona">
      <div class="container">
        <div class="ld-section-head">
          <span class="ld-kicker">C&oacute;mo funciona</span>
          <h2>Cuatro pasos, un proceso claro</h2>
          <p>Desde la idea inicial hasta la sustentaci&oacute;n final.</p>
        </div>

        <ol class="ld-steps">
          <li class="ld-step">
            <span class="ld-step-num">1</span>
            <h3>Inicia sesi&oacute;n</h3>
            <p>Ingresa con tu cuenta institucional; el sistema te muestra el panel seg&uacute;n tu rol.</p>
          </li>
          <li class="ld-step">
            <span class="ld-step-num">2</span>
            <h3>Postula tu idea</h3>
            <p>Explora el banco de ideas o registra tu anteproyecto para iniciar el proceso.</p>
          </li>
          <li class="ld-step">
            <span class="ld-step-num">3</span>
            <h3>Cumple las fases</h3>
            <p>Registra avances, recibe revisiones y obt&eacute;n los avales de tu profesor.</p>
          </li>
          <li class="ld-step">
            <span class="ld-step-num">4</span>
            <h3>Sustenta y finaliza</h3>
            <p>Presenta la sustentaci&oacute;n, recibe tu evaluaci&oacute;n y cierra el proceso.</p>
          </li>
        </ol>
      </div>
    </section>

    <!-- Llamado final -->
    <section class="ld-section">
      <div class="container">
        <div class="ld-cta">
          <div>
            <h2>&iquest;Listo para comenzar tu trabajo de grado?</h2>
            <p>Ingresa con tu cuenta institucional y retoma tu proceso donde lo dejaste.</p>
          </div>
          <a class="btn btn-lima ld-btn-hero" href="login.jsp">
            <i class="fa-solid fa-right-to-bracket"></i> Iniciar sesi&oacute;n
          </a>
        </div>
      </div>
    </section>

  </main>

  <!-- Pie -->
  <footer class="ld-footer">
    <div class="container ld-footer-inner">
      <div class="ld-brand">
        <span class="brand-logo"><i class="fa-solid fa-graduation-cap"></i></span>
        <span class="ld-brand-text">
          <strong>Ingenier&iacute;a de Sistemas</strong>
          <span>UTS</span>
        </span>
      </div>
      <p class="ld-footer-copy">Sistema de Trabajos de Grado &middot; UTS &copy; 2026</p>
      <a class="ld-footer-link" href="login.jsp">Iniciar sesi&oacute;n <i class="fa-solid fa-arrow-right"></i></a>
    </div>
  </footer>

</body>
</html>
