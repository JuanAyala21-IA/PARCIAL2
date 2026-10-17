# Imagen de la aplicacion "Trabajos de Grado" para Render.
# Tomcat 9 + Java 17; la aplicacion JSP se publica en el contexto raiz (/).
FROM tomcat:9.0-jdk17-temurin

# Plan free de Render: 512 MB de RAM / 0.1 CPU -> limitar el JVM.
ENV CATALINA_OPTS="-Xms48m -Xmx288m -XX:MaxMetaspaceSize=128m -XX:ReservedCodeCacheSize=64m -XX:+UseSerialGC -Dfile.encoding=UTF-8"

# Quitar las aplicaciones de ejemplo de Tomcat
RUN rm -rf /usr/local/tomcat/webapps/*

# Copiar la aplicacion (JSTL y MySQL Connector/J ya vienen en WEB-INF/lib)
COPY trabajos-grado/ /usr/local/tomcat/webapps/ROOT/

# Script de arranque: ajusta el puerto de Render y las credenciales de MySQL
COPY deploy/entrypoint.sh /usr/local/tomcat/bin/entrypoint.sh
RUN chmod +x /usr/local/tomcat/bin/entrypoint.sh

CMD ["/usr/local/tomcat/bin/entrypoint.sh"]
