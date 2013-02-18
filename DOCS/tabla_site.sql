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
-- Table structure for table `acc_site`
--

DROP TABLE IF EXISTS `acc_site`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acc_site` (
  `id_site` int(11) NOT NULL AUTO_INCREMENT,
  `site_code` varchar(50) NOT NULL,
  `contry` varchar(20) NOT NULL,
  PRIMARY KEY (`id_site`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acc_site`
--

LOCK TABLES `acc_site` WRITE;
/*!40000 ALTER TABLE `acc_site` DISABLE KEYS */;
INSERT INTO `acc_site` VALUES (1,'ATKU','Austria'),(2,'BRCM','Brasil'),(3,'CADO','Canada'),(4,'CHBE','Suiza'),(5,'CHBS','Suiza'),(6,'DENU','Alemania'),(7,'EGCA','Egipto'),(8,'INHY','India'),(9,'ITOR','Italia'),(10,'JPTO','Japon'),(11,'MXMC','Mexico'),(12,'PLWA',''),(13,'SIGX','Singapore'),(14,'TRGE',''),(15,'USAT','USA'),(16,'USBR','USA'),(17,'USEH','USA'),(18,'USEM','USA'),(19,'DEHO','Alemania'),(20,'DEBA','Alemania'),(21,'USBD','USA'),(22,'SGKC','Singapore'),(23,'SGSG','Singapore'),(24,'SGSZ','Singapore'),(25,'SGTU','Singapore'),(26,'UNKW','UNKNOW SITE'),(27,'USHS','USA'),(28,'DEMB','Alemania'),(29,'USMS','USA');
/*!40000 ALTER TABLE `acc_site` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-10-05 16:17:57
