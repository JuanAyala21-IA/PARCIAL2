@echo off
REM run-proyecto.bat - Inicia MySQL y Tomcat 9 y abre el sistema (sin reimportar la base)
cd /d C:\xampp

REM MySQL (si no esta corriendo)
tasklist /FI "IMAGENAME eq mysqld.exe" 2>NUL | find /I "mysqld.exe" >NUL
if errorlevel 1 (
  echo Iniciando MySQL...
  start "MySQL" /min mysql\bin\mysqld.exe --defaults-file=mysql\bin\my.ini --console
) else (
  echo MySQL ya esta corriendo.
)

REM Tomcat (si no esta corriendo)
powershell -NoProfile -Command "if (-not (Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue)) { exit 1 }" >NUL 2>&1
if errorlevel 1 (
  echo Iniciando Tomcat...
  start "Tomcat" /min tomcat\bin\startup.bat
) else (
  echo Tomcat ya esta corriendo.
)

REM Esperar al puerto 8080 (maximo 60 s)
echo Esperando a Tomcat en el puerto 8080...
powershell -NoProfile -Command "$t=0; while ($t -lt 60) { if (Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue) { exit 0 }; Start-Sleep 2; $t+=2 }; exit 1"
if errorlevel 1 (
  echo No se pudo contactar a Tomcat en 60 segundos. Revise tomcat\logs\catalina.*.log
  pause
  exit /b 1
)

start "" "http://localhost:8080/trabajos-grado/login.jsp"
echo Sistema abierto en http://localhost:8080/trabajos-grado/login.jsp
