<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%--
  conexion.jsp
  Unico lugar con los datos de conexion MySQL.
  Las paginas que necesiten BD lo incluyen con:
    <c:import url="includes/conexion.jsp" />
  y luego usan la fuente "db" en <sql:query> / <sql:update>.
  Ajustar url/user/password segun su MySQL (XAMPP por defecto: root sin clave).
--%>
<sql:setDataSource var="db"
  driver="com.mysql.cj.jdbc.Driver"
  url="jdbc:mysql://localhost:3306/trabajos_grado?useSSL=false&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8&connectionCollation=utf8mb4_general_ci"
  user="root"
  password=""
  scope="application" />
