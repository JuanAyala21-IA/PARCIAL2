#!/usr/bin/env bash
#
# entrypoint.sh - Arranque de la aplicacion en Render.
#
# 1) Ajusta el puerto HTTP de Tomcat al que Render asigna (variable PORT).
# 2) Escribe las credenciales de MySQL (Clever Cloud) en includes/conexion.jsp.
#
# Variables requeridas (se configuran en Render -> Environment):
#   DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
# Variable opcional:
#   DB_SSL_MODE  (PREFERRED | REQUIRED | DISABLED ; por defecto PREFERRED)
#
set -euo pipefail

SERVER_XML="/usr/local/tomcat/conf/server.xml"
CONEXION="/usr/local/tomcat/webapps/ROOT/includes/conexion.jsp"

# ---- 1) Puerto HTTP --------------------------------------------------------
if [ -n "${PORT:-}" ]; then
  sed -i "s/port=\"8080\"/port=\"${PORT}\"/" "$SERVER_XML"
  echo "[entrypoint] Tomcat escuchara en el puerto ${PORT}"
else
  echo "[entrypoint] Variable PORT no definida; se mantiene el puerto 8080"
fi

# ---- 2) Credenciales de la base de datos ----------------------------------
faltan=""
for var in DB_HOST DB_PORT DB_NAME DB_USER; do
  if [ -z "$(printenv "$var" 2>/dev/null || true)" ]; then
    faltan="${faltan} ${var}"
  fi
done
if [ -n "$faltan" ]; then
  echo "[entrypoint] ERROR: faltan variables de entorno:${faltan}" >&2
  echo "[entrypoint] Configuralas en el panel del servicio (Environment)." >&2
  exit 1
fi

DB_PASSWORD="${DB_PASSWORD:-}"
DB_SSL_MODE="${DB_SSL_MODE:-PREFERRED}"

JDBC_URL="jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?sslMode=${DB_SSL_MODE}&allowPublicKeyRetrieval=true&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8&connectionCollation=utf8mb4_general_ci"

# Escapa los caracteres especiales de sed (barra invertida, & y el delimitador #)
escapar() { printf '%s' "$1" | sed 's/[\\&#]/\\&/g'; }

JDBC_URL_E="$(escapar "$JDBC_URL")"
DB_USER_E="$(escapar "$DB_USER")"
DB_PASSWORD_E="$(escapar "$DB_PASSWORD")"

sed -i \
  -e "s#url=\"jdbc:mysql://[^\"]*\"#url=\"${JDBC_URL_E}\"#" \
  -e "s#user=\"[^\"]*\"#user=\"${DB_USER_E}\"#" \
  -e "s#password=\"[^\"]*\"#password=\"${DB_PASSWORD_E}\"#" \
  "$CONEXION"

if ! grep -q "jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}" "$CONEXION"; then
  echo "[entrypoint] ERROR: no se pudo actualizar includes/conexion.jsp" >&2
  exit 1
fi

echo "[entrypoint] Base de datos configurada: ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME} (TLS: ${DB_SSL_MODE})"

exec catalina.sh run
