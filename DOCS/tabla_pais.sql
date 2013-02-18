-- MySQL dump 10.13  Distrib 5.1.41, for debian-linux-gnu (i486)
--
-- Host: localhost    Database: digitalus
-- ------------------------------------------------------
-- Server version	5.1.41-3ubuntu12.6

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `acc_pais`
--

DROP TABLE IF EXISTS `acc_pais`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acc_pais` (
  `id_country` int(11) NOT NULL AUTO_INCREMENT,
  `pais` varchar(20) NOT NULL,
  PRIMARY KEY (`id_country`)
) ENGINE=InnoDB AUTO_INCREMENT=144 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acc_pais`
--

LOCK TABLES `acc_pais` WRITE;
/*!40000 ALTER TABLE `acc_pais` DISABLE KEYS */;
INSERT INTO `acc_pais` VALUES (1,'Albania'),(2,'Algeria'),(3,'Angola'),(4,'Argentina'),(5,'Aruba'),(6,'Australia'),(7,'Austria'),(8,'Bahamas'),(9,'Bahrain'),(10,'Bangladesh'),(11,'Barbados'),(12,'Belarus'),(13,'Belgium'),(14,'Belize'),(15,'Bermuda'),(16,'Bolivia'),(17,'Bosnia-Hercegovina'),(18,'Brazil'),(19,'Bulgaria'),(20,'Cameroon'),(21,'Canada'),(22,'Cayman Islands'),(23,'Chile'),(24,'China'),(25,'China Hong Kong'),(26,'Colombia'),(27,'Costa Rica'),(28,'Croatia'),(29,'Cuba'),(30,'Cyprus Rep'),(31,'Czech Republic'),(32,'Denmark'),(33,'Dominican Rep'),(34,'Ecuador'),(35,'Egypt'),(36,'Estonia'),(37,'Ethiopia'),(38,'Finland'),(39,'France'),(40,'Georgia'),(41,'Germany'),(42,'Ghana'),(43,'Gibraltar'),(44,'Greece'),(45,'Guadeloupe'),(46,'Guatemala'),(47,'Guyana'),(48,'Haiti'),(49,'Honduras Rep'),(50,'Hungary'),(51,'Iceland'),(52,'India'),(53,'Indonesia'),(54,'Iran'),(55,'Iraq'),(56,'Ireland'),(57,'Israel'),(58,'Italy'),(59,'Ivory Coast'),(60,'Jamaica'),(61,'Japan'),(62,'Jordan'),(63,'Kazakhstan Rep'),(64,'Kenya'),(65,'Korea South'),(66,'Kuwait'),(67,'Latvia'),(68,'Lebanon'),(69,'Liberia'),(70,'Liechtenstein'),(71,'Lithuania'),(72,'Luxembourg'),(73,'Macedonia FYROM'),(74,'Madagascar'),(75,'Malawi'),(76,'Malaysia'),(77,'Mali'),(78,'Malta'),(79,'Mexico'),(80,'Monaco'),(81,'Mongolia'),(82,'Morocco'),(83,'Mozambique'),(84,'Myanmar'),(85,'Netherlands'),(86,'Netherlands Antilles'),(87,'New Zealand'),(88,'Nicaragua'),(89,'Nigeria'),(90,'Norway'),(91,'Oman'),(92,'Pakistan'),(93,'Palestine'),(94,'Panama'),(95,'Paraguay'),(96,'Peop Rep Congo'),(97,'Peru'),(98,'Philippines'),(99,'Poland'),(100,'Portugal'),(101,'Puerto Rico'),(102,'Qatar'),(103,'Rep of Benin'),(104,'Republic of Yemen'),(105,'Romania'),(106,'Russian Federation'),(107,'Salvador El'),(108,'San Marino'),(109,'Saudi Arabia'),(110,'Senegal'),(111,'Serbia'),(112,'Serbia Repof'),(113,'Singapore'),(114,'Slovakia'),(115,'Slovenia'),(116,'South Africa'),(117,'Spain'),(118,'Sri Lanka'),(119,'Sudan'),(120,'Suriname'),(121,'Sweden'),(122,'Switzerland'),(123,'Syria'),(124,'Taiwan ROC'),(125,'Tanzania UnRepof'),(126,'Thailand'),(127,'Trinidad & Tobago'),(128,'Tunisia'),(129,'Turkey'),(130,'USA'),(131,'Uganda'),(132,'Ukraine'),(133,'United Arab Emirates'),(134,'United Kingdom'),(135,'Uruguay'),(136,'Uzbekistan'),(137,'Venezuela'),(138,'Vietnam'),(139,'Virgin Islands Brit'),(140,'Virgin Islands US'),(141,'Worldwide'),(142,'Zambia'),(143,'Zimbabwe');
/*!40000 ALTER TABLE `acc_pais` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-10-05 16:18:13
