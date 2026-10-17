# Publicar en internet: Render (aplicación) + Clever Cloud (base de datos)

Guía para dejar la aplicación funcionando en internet de forma gratuita:

- **Render** ejecuta la aplicación web dentro de un contenedor Docker con **Tomcat 9 + Java 17**.
- **Clever Cloud** aloja la base de datos **MySQL** (plan *DEV*, gratuito para pruebas).

```
Navegador  ->  https://NOMBRE.onrender.com        (Render: Tomcat 9 ejecuta los JSP)
                        |
                        +-- JDBC (MySQL Connector/J) --> Clever Cloud: MySQL 8.4
```

El repositorio ya incluye lo necesario:

| Archivo | Función |
|---|---|
| `Dockerfile` | Arma la imagen de Tomcat y copia la aplicación al contexto raíz (`/`). |
| `deploy/entrypoint.sh` | Al arrancar: ajusta el puerto de Render y escribe las credenciales de MySQL en `includes/conexion.jsp`. |
| `render.yaml` | (Opcional) define el servicio en Render con un clic ("Blueprint"). |
| `deploy/importar-bd.php` | Importador alternativo del respaldo (si el cliente `mysql` de XAMPP falla). |
| `.dockerignore` | Deja `docs/` y `sql/` fuera de la imagen. |

> Las credenciales **nunca** van en el código: se configuran como variables de entorno en Render.

---

## Paso 1. Crear la base de datos en Clever Cloud

1. Entra a https://console.clever-cloud.com y crea tu cuenta gratuita (no pide tarjeta; verifica el correo).
2. Botón **Create…** → **an add-on**.
3. Elige **MySQL**.
4. Opciones del add-on:
   - **Versión**: `8.4` (la que aparece por defecto).
   - **Plan**: `DEV` (gratuito, para pruebas: sin copias de seguridad ni SLA).
   - **Zona (region)**: la más cercana a Colombia, por ejemplo **Montréal**.
   - **Nombre**: por ejemplo `trabajos-grado-db`.
5. Crea el add-on y espera a que quede en estado **verde / Running**.
6. Abre el add-on y ubica la sección de **información de conexión** (*Connection info*). Anota estos cinco datos:
   - **Host**, **Port**, **Database**, **User**, **Password**
   (Clever Cloud también los muestra como variables `MYSQL_ADDON_HOST`, `MYSQL_ADDON_PORT`, `MYSQL_ADDON_DB`, `MYSQL_ADDON_USER`, `MYSQL_ADDON_PASSWORD`).
7. En ese mismo panel busca el enlace **phpMyAdmin** (lo usarás en el Paso 2).

---

## Paso 2. Exportar la base local e importarla a Clever Cloud

### 2.1 Exportar (en el PC, con MySQL de XAMPP encendido)

Abre **CMD** y ejecuta:

```bat
C:\xampp\mysql\bin\mysqldump.exe -u root --default-character-set=utf8mb4 --single-transaction --no-tablespaces trabajos_grado > "%TEMP%\trabajos_grado_cloud.sql"
```

Se crea el archivo `%TEMP%\trabajos_grado_cloud.sql` (≈18 KB) con tablas y datos.

### 2.2 Importar — Opción A (recomendada): phpMyAdmin de Clever Cloud

1. En el panel del add-on MySQL abre **phpMyAdmin**.
2. En la columna izquierda selecciona la base de datos (el nombre que viste en *Database*).
3. Pestaña **Importar** → **Choose file** → selecciona `%TEMP%\trabajos_grado_cloud.sql` → botón **Importar/Go**.

### 2.3 Importar — Opción B: línea de comandos

```bat
C:\xampp\mysql\bin\mysql.exe -h HOST -P PUERTO -u USUARIO -p --default-character-set=utf8mb4 BASE < "%TEMP%\trabajos_grado_cloud.sql"
```

(Reemplaza HOST, PUERTO, USUARIO y BASE por los datos del add-on; te pedirá la contraseña).

Si el cliente de XAMPP falla por el tipo de autenticación de MySQL 8.4, usa el importador en PHP incluido:

```bat
C:\xampp\php\php.exe deploy\importar-bd.php HOST PUERTO USUARIO PASSWORD BASE "%TEMP%\trabajos_grado_cloud.sql"
```

### 2.4 Verificar

En phpMyAdmin deben aparecer las 10 tablas (`usuarios`, `anteproyectos`, `entregas`, …).
La tabla `usuarios` debe tener **18 filas**.

---

## Paso 3. Subir el código a GitHub

Desde `C:\xampp\tomcat\webapps\PARCIAL2` (una sola vez):

```bat
git config user.name  "TU NOMBRE"
git config user.email "TU_CORREO@ejemplo.com"
git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
git add -A
git commit -m "Aplicacion trabajos de grado + despliegue Render/Clever Cloud"
git push -u origin main
```

Si el repositorio se creó con un README y el push es rechazado:

```bat
git pull --rebase origin main
git push -u origin main
```

---

## Paso 4. Crear el servicio web en Render

1. Entra a https://dashboard.render.com (regístrate con GitHub si aún no tienes cuenta).
2. **New +** → **Web Service** → *Build and deploy from a Git repository* → elige tu repositorio
   (si es privado, autoriza la *GitHub App* de Render).
3. Configura así:

   | Campo | Valor |
   |---|---|
   | Language (Runtime) | **Docker** |
   | Dockerfile Path | `./Dockerfile` |
   | Region | **Ohio** (la más cercana) |
   | Instance Type | **Free** |
   | Name | el que quieras (forma la URL: `https://NOMBRE.onrender.com`) |

4. En **Environment Variables** agrega una por una (valores del Paso 1):

   | Variable en Render | Valor (Clever Cloud) |
   |---|---|
   | `DB_HOST` | Host |
   | `DB_PORT` | Port |
   | `DB_NAME` | Database |
   | `DB_USER` | User |
   | `DB_PASSWORD` | Password |
   | `DB_SSL_MODE` | `PREFERRED` |

5. **Create Web Service** y espera el despliegue (la primera vez tarda varios minutos).
6. Cuando el log muestre `[entrypoint] Base de datos configurada: ...`, abre:

   **https://NOMBRE.onrender.com/** → te llevará al inicio de sesión.

> Alternativa con el archivo `render.yaml`: **New + → Blueprint** → elige el repositorio →
> Render detecta la configuración y solo te pedirá los valores de las variables.

---

## Paso 5. Probar

- Inicia sesión con un usuario de los datos de prueba, por ejemplo `admin@uts.edu.co` / `admin123`.
- Recorre usuarios, proyectos e ideas para confirmar que las consultas funcionan contra Clever Cloud.

> **Nota (plan gratuito):** si el servicio pasa 15 minutos sin visitas, Render "duerme" la
> aplicación; la siguiente visita tarda alrededor de 1 minuto en despertar. Es normal.

---

## Actualizar la aplicación / los datos

| Qué cambió | Qué hacer |
|---|---|
| Código JSP/CSS | `git add -A`, `git commit`, `git push` → Render redespliega solo. |
| Datos de la base | Exportar de nuevo (paso 2.1) e importar en phpMyAdmin (reemplaza las tablas). |
| Credenciales de Clever Cloud | Render → Environment → editar → Save (el servicio se reinicia). |
| Variable nueva | Render → Environment → Add Environment Variable. |

---

## Problemas comunes

| Síntoma | Causa probable / solución |
|---|---|
| El build falla con "COPY failed" | El repositorio debe tener `Dockerfile` en la raíz y la carpeta `trabajos-grado/`. |
| Log: `faltan variables de entorno: DB_HOST` | Faltan variables en *Environment* de Render. |
| La app muestra error de base de datos | Verifica host/puerto/usuario/clave. Prueba `DB_SSL_MODE` con `REQUIRED` o `DISABLED`. |
| Página "Application loading" de Render | El servicio está despertando (plan free). Espera ~1 minuto. |
| Tomcat se reinicia solo (falta de memoria) | Reduce `-Xmx` en el `Dockerfile` (por ejemplo a `-Xmx256m`) y vuelve a desplegar. |
| El push pide usuario/contraseña | Usa un *token* de GitHub o el navegador (Git Credential Manager). |
| La importación falla por autenticación | Usa phpMyAdmin (Opción A) o el importador PHP (Opción B). |

---

## Notas de seguridad

- Las credenciales viven únicamente en las variables de entorno de Render y en tu PC; no se suben al repositorio.
- El plan DEV de Clever Cloud **no** tiene copias de seguridad: si haces cambios importantes en los datos, vuelve a exportar.
- El plan free de Render tiene disco efímero: no guardes archivos en el servidor (la aplicación solo registra enlaces, así que no hay problema).
