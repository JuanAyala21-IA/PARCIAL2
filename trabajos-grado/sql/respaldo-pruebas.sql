-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: trabajos_grado
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `anteproyectos`
--

DROP TABLE IF EXISTS `anteproyectos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `anteproyectos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(10) NOT NULL COMMENT 'Formato GRA-00001',
  `descripcion` text NOT NULL,
  `estudiante_id` int(11) DEFAULT NULL,
  `director_id` int(11) DEFAULT NULL,
  `evaluador_id` int(11) DEFAULT NULL,
  `fase` varchar(30) NOT NULL DEFAULT 'ANTEPROYECTO',
  `estado` varchar(30) NOT NULL DEFAULT 'EN_REVISION',
  `fecha_registro` timestamp NOT NULL DEFAULT current_timestamp(),
  `idea_id` int(11) DEFAULT NULL COMMENT 'Idea del banco seleccionada por el estudiante',
  `idea_solicitada_id` int(11) DEFAULT NULL COMMENT 'Idea elegida por el estudiante en Fase 1',
  `obs_coordinacion` text DEFAULT NULL COMMENT 'Observaciones al devolver la solicitud de Fase 1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo` (`codigo`),
  KEY `fk_ante_estudiante` (`estudiante_id`),
  KEY `fk_ante_director` (`director_id`),
  KEY `fk_ante_evaluador` (`evaluador_id`),
  KEY `fk_ante_idea` (`idea_id`),
  KEY `fk_ante_idea_sol` (`idea_solicitada_id`),
  CONSTRAINT `fk_ante_director` FOREIGN KEY (`director_id`) REFERENCES `usuarios` (`id`),
  CONSTRAINT `fk_ante_estudiante` FOREIGN KEY (`estudiante_id`) REFERENCES `usuarios` (`id`),
  CONSTRAINT `fk_ante_evaluador` FOREIGN KEY (`evaluador_id`) REFERENCES `usuarios` (`id`),
  CONSTRAINT `fk_ante_idea` FOREIGN KEY (`idea_id`) REFERENCES `ideas` (`id`),
  CONSTRAINT `fk_ante_idea_sol` FOREIGN KEY (`idea_solicitada_id`) REFERENCES `ideas` (`id`),
  CONSTRAINT `ck_ante_fase` CHECK (`fase` in ('1','2','3','4','5','FINAL','IDEA','ANTEPROYECTO','PROYECTO','SUSTENTACION')),
  CONSTRAINT `ck_ante_estado` CHECK (`estado` in ('ESTUDIANTE','DIRECTOR','EVALUADOR','COORDINACION','APROBADO','RECHAZADO','FINALIZADO','EN_REVISION','EN_DESARROLLO'))
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `anteproyectos`
--

LOCK TABLES `anteproyectos` WRITE;
/*!40000 ALTER TABLE `anteproyectos` DISABLE KEYS */;
INSERT INTO `anteproyectos` VALUES (1,'GRA-90001','Riego automatizado con IoT',7,NULL,NULL,'1','ESTUDIANTE','2026-10-14 19:57:05',NULL,NULL,NULL),(2,'GRA-90002','App de tutorías UTS',8,NULL,NULL,'1','COORDINACION','2026-10-14 19:57:05',NULL,2,NULL),(3,'GRA-90003','Detección de plagas con visión artificial',9,3,5,'3','EVALUADOR','2026-10-14 19:57:05',3,3,NULL),(4,'GRA-90004','Historias clínicas digitales',10,3,5,'3','EVALUADOR','2026-10-14 19:57:05',4,4,NULL),(5,'GRA-90005','Monitoreo de calidad del aire',11,4,6,'3','EVALUADOR','2026-10-14 19:57:05',5,5,NULL);
/*!40000 ALTER TABLE `anteproyectos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `calendario`
--

DROP TABLE IF EXISTS `calendario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `calendario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `actividad` varchar(200) NOT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `descripcion` text DEFAULT NULL,
  `titulo` varchar(200) DEFAULT NULL COMMENT 'Titulo del evento',
  `tipo` varchar(20) NOT NULL DEFAULT 'OTRO' COMMENT 'ENTREGA, REUNION, SUSTENTACION u OTRO',
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_calendario_tipo` CHECK (`tipo` in ('ENTREGA','REUNION','SUSTENTACION','OTRO'))
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `calendario`
--

LOCK TABLES `calendario` WRITE;
/*!40000 ALTER TABLE `calendario` DISABLE KEYS */;
INSERT INTO `calendario` VALUES (1,'','2026-10-14',NULL,'Último día para inscribir anteproyectos.','Cierre de inscripciones','ENTREGA'),(2,'','2026-10-29',NULL,'Revisión de avances con el comité.','Reunión de comité','REUNION'),(3,'','2026-10-19','2026-10-24','Sustentaciones públicas de grado.','Semana de sustentaciones','SUSTENTACION'),(4,'','2026-11-18',NULL,'Exposición de proyectos del semestre.','Feria de proyectos','OTRO');
/*!40000 ALTER TABLE `calendario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `entregas`
--

DROP TABLE IF EXISTS `entregas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entregas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `anteproyecto_id` int(11) NOT NULL,
  `fase` varchar(2) NOT NULL COMMENT '1..5',
  `enlace` varchar(500) NOT NULL COMMENT 'URL a Drive, OneDrive, etc. Nunca archivos',
  `comentario` text DEFAULT NULL,
  `enviado_por` int(11) DEFAULT NULL,
  `fecha_envio` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_entregas_anteproyecto` (`anteproyecto_id`),
  KEY `fk_entregas_usuario` (`enviado_por`),
  CONSTRAINT `fk_entregas_anteproyecto` FOREIGN KEY (`anteproyecto_id`) REFERENCES `anteproyectos` (`id`),
  CONSTRAINT `fk_entregas_usuario` FOREIGN KEY (`enviado_por`) REFERENCES `usuarios` (`id`),
  CONSTRAINT `ck_entregas_fase` CHECK (`fase` in ('1','2','3','4','5'))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `entregas`
--

LOCK TABLES `entregas` WRITE;
/*!40000 ALTER TABLE `entregas` DISABLE KEYS */;
INSERT INTO `entregas` VALUES (1,1,'1','https://drive.google.com/file/d/pago90001/view','Comprobante de pago.',7,'2026-10-14 14:57:05'),(2,2,'1','https://drive.google.com/file/d/pago90002/view','Comprobante de pago revisado.',8,'2026-10-14 14:57:05'),(3,3,'2','https://drive.google.com/file/d/propuesta90003/view','Propuesta versión 1.',9,'2026-10-14 14:57:05');
/*!40000 ALTER TABLE `entregas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `evaluaciones`
--

DROP TABLE IF EXISTS `evaluaciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `evaluaciones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `anteproyecto_id` int(11) NOT NULL,
  `fase` varchar(2) NOT NULL COMMENT '3 o 5 (fases que evalua el evaluador)',
  `evaluador_id` int(11) DEFAULT NULL,
  `observaciones` text DEFAULT NULL,
  `decision` varchar(10) NOT NULL COMMENT 'APROBADO o DEVUELTO',
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_evaluaciones_anteproyecto` (`anteproyecto_id`),
  KEY `fk_evaluaciones_evaluador` (`evaluador_id`),
  CONSTRAINT `fk_evaluaciones_anteproyecto` FOREIGN KEY (`anteproyecto_id`) REFERENCES `anteproyectos` (`id`),
  CONSTRAINT `fk_evaluaciones_evaluador` FOREIGN KEY (`evaluador_id`) REFERENCES `usuarios` (`id`),
  CONSTRAINT `ck_evaluaciones_decision` CHECK (`decision` in ('APROBADO','DEVUELTO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evaluaciones`
--

LOCK TABLES `evaluaciones` WRITE;
/*!40000 ALTER TABLE `evaluaciones` DISABLE KEYS */;
/*!40000 ALTER TABLE `evaluaciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `formatos`
--

DROP TABLE IF EXISTS `formatos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `formatos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `archivo_url` varchar(255) DEFAULT NULL COMMENT 'Ruta o URL del documento',
  `estado` varchar(10) NOT NULL DEFAULT 'ACTIVO',
  `categoria` varchar(20) NOT NULL DEFAULT 'OTRO' COMMENT 'ANTEPROYECTO, INFORME, SUSTENTACION u OTRO',
  `enlace` varchar(500) DEFAULT NULL COMMENT 'URL al documento (Drive, OneDrive, etc.)',
  `fecha_registro` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  CONSTRAINT `ck_formatos_estado` CHECK (`estado` in ('ACTIVO','INACTIVO')),
  CONSTRAINT `ck_formatos_categoria` CHECK (`categoria` in ('ANTEPROYECTO','INFORME','SUSTENTACION','OTRO'))
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `formatos`
--

LOCK TABLES `formatos` WRITE;
/*!40000 ALTER TABLE `formatos` DISABLE KEYS */;
INSERT INTO `formatos` VALUES (1,'Formato de anteproyecto','Plantilla oficial del documento de anteproyecto.',NULL,'ACTIVO','ANTEPROYECTO','https://ejemplo.uts.edu.co/formatos/anteproyecto','2026-10-14 19:57:05'),(2,'Formato de informe final','Plantilla del informe final del proyecto.',NULL,'ACTIVO','INFORME','https://ejemplo.uts.edu.co/formatos/informe','2026-10-14 19:57:05'),(3,'Formato de sustentación','Guía y rúbrica de la sustentación.',NULL,'ACTIVO','SUSTENTACION','https://ejemplo.uts.edu.co/formatos/sustentacion','2026-10-14 19:57:05'),(4,'Formato de solicitud general','Solicitudes varias a coordinación.',NULL,'ACTIVO','OTRO','https://ejemplo.uts.edu.co/formatos/solicitud','2026-10-14 19:57:05');
/*!40000 ALTER TABLE `formatos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ideas`
--

DROP TABLE IF EXISTS `ideas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ideas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `titulo` varchar(200) NOT NULL,
  `descripcion` text NOT NULL,
  `area` varchar(100) DEFAULT NULL,
  `propuesta_por` int(11) DEFAULT NULL COMMENT 'FK a usuarios.id (quien propone la idea)',
  `estado` varchar(20) NOT NULL DEFAULT 'DISPONIBLE',
  `fecha_registro` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_ideas_usuario` (`propuesta_por`),
  CONSTRAINT `fk_ideas_usuario` FOREIGN KEY (`propuesta_por`) REFERENCES `usuarios` (`id`),
  CONSTRAINT `ck_ideas_estado` CHECK (`estado` in ('DISPONIBLE','ASIGNADA','INACTIVA'))
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ideas`
--

LOCK TABLES `ideas` WRITE;
/*!40000 ALTER TABLE `ideas` DISABLE KEYS */;
INSERT INTO `ideas` VALUES (1,'Riego automatizado con IoT','Sistema de riego controlado por sensores de humedad y app móvil.','IoT',2,'DISPONIBLE','2026-10-14 19:57:05'),(2,'App de tutorías UTS','Plataforma para agendar tutorías entre estudiantes y docentes.','Desarrollo web',2,'DISPONIBLE','2026-10-14 19:57:05'),(3,'Detección de plagas con visión artificial','Modelo de IA para detectar plagas en cultivos de la región.','Inteligencia artificial',2,'ASIGNADA','2026-10-14 19:57:05'),(4,'Historias clínicas digitales','Sistema de gestión de historias clínicas para IPS locales.','Salud digital',2,'ASIGNADA','2026-10-14 19:57:05'),(5,'Monitoreo de calidad del aire','Red de sensores de bajo costo con tablero público.','IoT',2,'ASIGNADA','2026-10-14 19:57:05'),(6,'Reciclaje inteligente en campus','Puntos limpios con sensores de llenado y rutas óptimas.','Sostenibilidad',2,'DISPONIBLE','2026-10-14 19:57:05');
/*!40000 ALTER TABLE `ideas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `revisiones`
--

DROP TABLE IF EXISTS `revisiones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `revisiones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `anteproyecto_id` int(11) NOT NULL,
  `fase` varchar(2) NOT NULL COMMENT '2 o 4 (fases que revisa el director)',
  `director_id` int(11) DEFAULT NULL,
  `observaciones` text DEFAULT NULL,
  `decision` varchar(10) NOT NULL COMMENT 'APROBADO o DEVUELTO',
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_revisiones_anteproyecto` (`anteproyecto_id`),
  KEY `fk_revisiones_director` (`director_id`),
  CONSTRAINT `fk_revisiones_anteproyecto` FOREIGN KEY (`anteproyecto_id`) REFERENCES `anteproyectos` (`id`),
  CONSTRAINT `fk_revisiones_director` FOREIGN KEY (`director_id`) REFERENCES `usuarios` (`id`),
  CONSTRAINT `ck_revisiones_decision` CHECK (`decision` in ('APROBADO','DEVUELTO'))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `revisiones`
--

LOCK TABLES `revisiones` WRITE;
/*!40000 ALTER TABLE `revisiones` DISABLE KEYS */;
INSERT INTO `revisiones` VALUES (1,4,'2',3,'Propuesta aprobada con ajustes menores.','APROBADO','2026-10-14 14:57:05'),(2,5,'2',4,'Propuesta aprobada.','APROBADO','2026-10-14 14:57:05'),(3,3,'2',3,'','APROBADO','2026-10-14 15:46:02');
/*!40000 ALTER TABLE `revisiones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(30) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'ADMINISTRADOR'),(2,'COORDINACION'),(3,'DIRECTOR'),(5,'ESTUDIANTE'),(4,'EVALUADOR');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(20) DEFAULT NULL,
  `nombre` varchar(100) NOT NULL,
  `correo` varchar(100) NOT NULL,
  `password` varchar(128) NOT NULL COMMENT 'Hash SHA2 256 en hexadecimal (64 caracteres)',
  `rol_id` int(11) NOT NULL,
  `estado` varchar(10) NOT NULL DEFAULT 'ACTIVO',
  PRIMARY KEY (`id`),
  UNIQUE KEY `correo` (`correo`),
  UNIQUE KEY `codigo` (`codigo`),
  KEY `fk_usuarios_rol` (`rol_id`),
  CONSTRAINT `fk_usuarios_rol` FOREIGN KEY (`rol_id`) REFERENCES `roles` (`id`),
  CONSTRAINT `ck_usuarios_estado` CHECK (`estado` in ('ACTIVO','INACTIVO'))
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,'ADM-001','Administrador del Sistema','admin@uts.edu.co','240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9',1,'ACTIVO'),(2,'COR-001','Coordinación Uno','coordinacion@uts.edu.co','ff960cb55673958c594d0daaab1e368651c75c02f9687192a1811e7b180336a7',2,'ACTIVO'),(3,'DIR-001','Director Uno','director1@uts.edu.co','ff960cb55673958c594d0daaab1e368651c75c02f9687192a1811e7b180336a7',3,'ACTIVO'),(4,'DIR-002','Director Dos','director2@uts.edu.co','ff960cb55673958c594d0daaab1e368651c75c02f9687192a1811e7b180336a7',3,'ACTIVO'),(5,'EVA-001','Evaluador Uno','evaluador1@uts.edu.co','ff960cb55673958c594d0daaab1e368651c75c02f9687192a1811e7b180336a7',4,'ACTIVO'),(6,'EVA-002','Evaluador Dos','evaluador2@uts.edu.co','ff960cb55673958c594d0daaab1e368651c75c02f9687192a1811e7b180336a7',4,'ACTIVO'),(7,'EST-001','Estudiante Uno','estudiante1@uts.edu.co','ff960cb55673958c594d0daaab1e368651c75c02f9687192a1811e7b180336a7',5,'ACTIVO'),(8,'EST-002','Estudiante Dos','estudiante2@uts.edu.co','ff960cb55673958c594d0daaab1e368651c75c02f9687192a1811e7b180336a7',5,'ACTIVO'),(9,'EST-003','Estudiante Tres','estudiante3@uts.edu.co','ff960cb55673958c594d0daaab1e368651c75c02f9687192a1811e7b180336a7',5,'ACTIVO'),(10,'EST-004','Estudiante Cuatro','estudiante4@uts.edu.co','ff960cb55673958c594d0daaab1e368651c75c02f9687192a1811e7b180336a7',5,'ACTIVO'),(11,'EST-005','Estudiante Cinco','estudiante5@uts.edu.co','ff960cb55673958c594d0daaab1e368651c75c02f9687192a1811e7b180336a7',5,'ACTIVO'),(12,'EST-021','Juan Jose Ayala Delgado','jjoseayala@uts.edu.co','ff960cb55673958c594d0daaab1e368651c75c02f9687192a1811e7b180336a7',5,'ACTIVO');
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-14 17:15:47
