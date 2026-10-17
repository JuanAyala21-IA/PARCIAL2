# Guía de demostración — Trabajos de Grado (UTS)

## a) Despliegue en Tomcat 9 con XAMPP

1. Copie la carpeta `trabajos-grado` a `C:\xampp\tomcat\webapps\` (URL: `http://localhost:8080/trabajos-grado` → `login.jsp`).
2. Copie en `WEB-INF\lib` los JAR: `jstl-1.2.jar` y `mysql-connector-j-8.x.jar`.
3. En XAMPP Control Panel inicie **MySQL** y **Tomcat**.
4. En phpMyAdmin (`http://localhost/phpmyadmin`), pestaña Importar, en orden: `sql/schema.sql`, luego `sql/cambios.sql` completo (bloques 1–18), luego `sql/datos-prueba.sql`.

## b) Usuarios de prueba (clave: `prueba123`, salvo admin)

| Correo | Rol | Clave |
|---|---|---|
| `admin@uts.edu.co` | ADMINISTRADOR | `admin123` |
| `coordinacion@uts.edu.co` | COORDINACION | `prueba123` |
| `director1@uts.edu.co` / `director2@uts.edu.co` | PROFESOR | `prueba123` |
| `evaluador1@uts.edu.co` / `evaluador2@uts.edu.co` | PROFESOR | `prueba123` |
| `estudiante1@uts.edu.co` … `estudiante5@uts.edu.co` | ESTUDIANTE | `prueba123` |

## c) Guion de demostración (~10 min, en orden del flujo)

1. **Admin (2 min):** entra como `admin@uts.edu.co`; Usuarios → buscar, paginar; Nuevo usuario (probar duplicado y claves distintas). Eliminar usuario: si no tiene historial se borra directo; si tiene historial se abre la pantalla de confirmación con el resumen y dos alternativas: "Marcar como INACTIVO" o "Eliminar definitivamente" escribiendo `ELIMINAR` (con aviso rojo "Esta acción no se puede deshacer…"). Un PROFESOR/COORDINACION/ADMINISTRADOR con historial debe elegir a quién transferirlo (solo aparecen herederos válidos; un profesor no puede recibir proyectos donde sería el otro responsable); los estudiantes conservan el proyecto cuando hay compañero (el compañero pasa a principal). Nunca se puede eliminar al propio administrador ni al único administrador activo (`error=propio` / `error=ultimo-admin`), y una relación no cubierta bloquea el borrado nombrando la tabla.
2. **Estudiante (1 min):** `estudiante1@uts.edu.co` → Mis proyectos → "Iniciar proyecto de grado" (o ver el GRA-90001 ya creado) → Fase 1: sube el pago; pestaña "2. Idea": elige del banco o postula su propia idea (queda con estado POSTULADA, una por equipo; Coordinación la aprueba o devuelve); pestaña "3. Equipo" (opcional): buscar un compañero por nombre, código o correo y agregarlo mientras la Fase 1 siga en turno Estudiante (también se puede quitar). En equipo, solo una persona sube el enlace de cada fase: si un miembro ya tiene enlaces, el otro ve la alerta "<nombre> ya subió el enlace de esta fase" sin formulario ni botones (y su POST se rechaza); si el que subió elimina sus enlaces, la fase se libera y el otro puede subir. El botón "Enviar" y los requisitos (con "Subido por <nombre>") quedan iguales para ambos → Enviar a Coordinación.
3. **Coordinación (1 min):** `coordinacion@uts.edu.co` → ver "Solicitudes pendientes" → GRA-90002 (fase 1, COORDINACION) → Atender solicitud (revisar pago e idea: del banco o con la insignia "Propuesta por el estudiante"; muestra también al compañero(a) si el proyecto es en equipo) → asigna idea, director y evaluador → Fase 2.
4. **Estudiante (1 min):** `estudiante3@uts.edu.co` → Fase 2 del GRA-90003 → registrar enlace → "Enviar al Director".
5. **Profesor director (2 min):** `director1@uts.edu.co` (rol PROFESOR) → GRA-90003 → Revisar (hilo con autor y rol) → botón “Subir mi versión (enlace)” hacia `entrega.jsp?fase=2` en su turno (reemplaza al enlace actual del hilo; el pago de fase 1 nunca se toca) → Aprobar → Fase 3; mostrar devolución en otro caso. Cada quien solo edita o elimina sus propios enlaces.
6. **Coordinación (1 min):** GRA-90005 (fase 3, con evaluador) → proyecto-ver muestra idea solicitada y asignada.
7. **Profesor evaluador (1 min):** `evaluador1@uts.edu.co` (rol PROFESOR) → GRA-90004 → Evaluar (hilo 2+3 con autor y rol) → puede subir su versión en `entrega.jsp?fase=3` en su turno (reemplaza al enlace anterior del hilo) → "Aprobar y enviar a Coordinación": queda en la misma fase con turno Coordinación (aval pendiente). Un mismo profesor puede dirigir unos proyectos y evaluar otros, pero nunca ser director y evaluador del mismo proyecto.
8. **Coordinación avala (1 min):** `coordinacion@uts.edu.co` → "Avales pendientes: N" → `mis-proyectos.jsp?avales=1` → GRA-90004 (fase 3, Coordinación (aval)) → botón "Avalar decisión del evaluador" (fa-file-signature) → `avalar.jsp`: verifica enlaces de la fase 2, última decisión del director (revisiones) y del evaluador (evaluaciones) → "Avalar y continuar" (fase 3→4/ESTUDIANTE, fase 5→FINAL/COORDINACION) o "No avalar y devolver al evaluador" (misma fase, turno EVALUADOR, con observaciones; el evaluador ve "Coordinación no avaló tu aprobación anterior" y puede aprobar de nuevo o devolver al estudiante 3→2/5→4).
9. **Cierre (1 min):** Informes (pestañas + collapse), Calendario (mes actual, evento de hoy resaltado) y Base documental (abrir formato).
9. **Sustentación (2 min):** `coordinacion@uts.edu.co` → proyecto en fase `FINAL` → Sustentación: registra fecha y la única nota del sistema, y marca FINALIZADO; los demás roles solo consultan fecha, nota y estado.

## d) Si algo falla

1. **Conector JAR faltante:** `ClassNotFoundException com.mysql...` → copie `mysql-connector-j` en `WEB-INF\lib` y reinicie Tomcat.
2. **Tomcat 10 en vez de 9:** las etiquetas `java.sun.com` no resuelven (`jakarta.*`) → use Tomcat 9.
3. **Base no creada:** "Unknown database" → importe `schema.sql` (crea `trabajos_grado`).
4. **Bloque de cambios sin ejecutar:** error en `idea_id`, `título`/`tipo` nulos o CHECK (`fase '2'`, `estado 'DIRECTOR'`) → importe `cambios.sql` completo.
5. **CHECK ignorado (MySQL 5.7):** `DROP CHECK` falla → ejecute solo los `ADD COLUMN`/`CREATE TABLE` e ignore ese error (los CHECK no se aplican ahí).
