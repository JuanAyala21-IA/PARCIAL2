# Sistema de Trabajos de Grado (UTS)

Aplicación web académica en **JSP + JSTL + MySQL** (sin servlets ni scriptlets) para gestionar
trabajos de grado: usuarios y roles, banco de ideas, anteproyectos, avales, evaluaciones,
entregas, revisiones, calendario institucional y formatos.

## Contenido del repositorio

| Ruta | Descripción |
|---|---|
| `trabajos-grado/` | La aplicación web (páginas JSP, `includes/`, `WEB-INF/`, `css/`). |
| `trabajos-grado/sql/` | Scripts de base de datos: `schema.sql`, `cambios.sql`, `datos-prueba.sql`. |
| `trabajos-grado/docs/` | Documentación: guía de demostración, matriz de roles y guía de despliegue. |
| `Dockerfile` + `deploy/` | Empaquetado para publicar la aplicación en Render (Tomcat 9 + Java 17). |
| `render.yaml` | Definición opcional del servicio en Render ("Blueprint"). |

## Ejecución local

1. Iniciar XAMPP (MySQL) y Tomcat 9.
2. Ejecutar los scripts de `trabajos-grado/sql/` (schema → cambios → datos de prueba) en MySQL.
3. Abrir `http://localhost:8080/trabajos-grado/`.

## Publicación en internet (gratuita)

Guía paso a paso: [`trabajos-grado/docs/despliegue-nube.md`](trabajos-grado/docs/despliegue-nube.md)

- Aplicación → **Render** (plan free, Docker + Tomcat 9).
- Base de datos → **Clever Cloud** (MySQL, plan DEV gratuito para pruebas).
