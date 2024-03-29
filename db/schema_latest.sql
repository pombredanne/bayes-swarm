-- MySQL dump 10.11
--
-- Host: localhost    Database: swarm
-- ------------------------------------------------------
-- Server version	5.0.51a-3ubuntu5.4-log

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
-- Table structure for table `globalize_countries`
--

DROP TABLE IF EXISTS `globalize_countries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `globalize_countries` (
  `id` int(11) NOT NULL auto_increment,
  `code` char(2) default NULL,
  `english_name` varchar(255) default NULL,
  `date_format` varchar(255) default NULL,
  `currency_format` varchar(255) default NULL,
  `currency_code` char(3) default NULL,
  `thousands_sep` char(2) default NULL,
  `decimal_sep` char(2) default NULL,
  `currency_decimal_sep` char(2) default NULL,
  `number_grouping_scheme` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_globalize_countries_on_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=240 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `globalize_languages`
--

DROP TABLE IF EXISTS `globalize_languages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `globalize_languages` (
  `id` int(11) NOT NULL auto_increment,
  `iso_639_1` char(2) default NULL,
  `iso_639_2` char(3) default NULL,
  `iso_639_3` char(3) default NULL,
  `rfc_3066` varchar(255) default NULL,
  `english_name` varchar(255) default NULL,
  `english_name_locale` varchar(255) default NULL,
  `english_name_modifier` varchar(255) default NULL,
  `native_name` varchar(255) default NULL,
  `native_name_locale` varchar(255) default NULL,
  `native_name_modifier` varchar(255) default NULL,
  `macro_language` tinyint(1) default NULL,
  `direction` varchar(255) default NULL,
  `pluralization` varchar(255) default NULL,
  `scope` char(1) default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_globalize_languages_on_iso_639_1` (`iso_639_1`),
  KEY `index_globalize_languages_on_iso_639_2` (`iso_639_2`),
  KEY `index_globalize_languages_on_iso_639_3` (`iso_639_3`),
  KEY `index_globalize_languages_on_rfc_3066` (`rfc_3066`)
) ENGINE=InnoDB AUTO_INCREMENT=7597 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `globalize_translations`
--

DROP TABLE IF EXISTS `globalize_translations`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `globalize_translations` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(255) default NULL,
  `tr_key` varchar(255) default NULL,
  `table_name` varchar(255) default NULL,
  `item_id` int(11) default NULL,
  `facet` varchar(255) default NULL,
  `built_in` tinyint(1) default '1',
  `language_id` int(11) default NULL,
  `pluralization_index` int(11) default NULL,
  `text` text,
  `namespace` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_globalize_translations_on_tr_key_and_language_id` (`tr_key`,`language_id`),
  KEY `globalize_translations_table_name_and_item_and_language` (`table_name`,`item_id`,`language_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7180 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `intwords`
--

DROP TABLE IF EXISTS `intwords`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `intwords` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  `language_id` int(11) NOT NULL default '0',
  `visible` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  USING BTREE (`id`),
  KEY `fk_int_words_language` (`language_id`),
  KEY `idx_id_lang_visible` (`id`,`language_id`,`visible`)
) ENGINE=MyISAM AUTO_INCREMENT=79170 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `kinds`
--

DROP TABLE IF EXISTS `kinds`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `kinds` (
  `id` int(11) NOT NULL auto_increment,
  `kind` char(3) NOT NULL default '',
  PRIMARY KEY  USING BTREE (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `pages`
--

DROP TABLE IF EXISTS `pages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `pages` (
  `id` int(11) NOT NULL auto_increment,
  `source_id` int(11) NOT NULL default '0',
  `url` varchar(255) NOT NULL default '',
  `last_scantime` datetime NOT NULL default '0000-00-00 00:00:00',
  `kind_id` int(11) NOT NULL default '0',
  `language_id` int(11) NOT NULL default '0',
  `created_at` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  USING BTREE (`id`),
  KEY `fk_page_source` (`source_id`),
  KEY `fk_page_kind` (`kind_id`),
  KEY `fk_page_language` (`language_id`),
  CONSTRAINT `fk_page_kind` FOREIGN KEY (`kind_id`) REFERENCES `kinds` (`id`),
  CONSTRAINT `fk_page_language` FOREIGN KEY (`language_id`) REFERENCES `globalize_languages` (`id`),
  CONSTRAINT `fk_page_source` FOREIGN KEY (`source_id`) REFERENCES `sources` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=191 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `sources`
--

DROP TABLE IF EXISTS `sources`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `sources` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(100) NOT NULL default '',
  `created_at` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  USING BTREE (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=103 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(100) default NULL,
  `fullname` varchar(100) default NULL,
  `email` varchar(100) default NULL,
  `hashed_password` varchar(40) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `words`
--

DROP TABLE IF EXISTS `words`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `words` (
  `id` int(11) NOT NULL auto_increment,
  `intword_id` int(11) NOT NULL default '0',
  `page_id` int(11) NOT NULL default '0',
  `scantime` date NOT NULL default '0000-00-00',
  `count` int(11) NOT NULL default '0',
  `bodycount` int(11) NOT NULL default '0',
  `titlecount` int(11) NOT NULL default '0',
  `keywordcount` int(11) NOT NULL default '0',
  `anchorcount` int(11) NOT NULL default '0',
  `headingcount` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `fk_word_page` (`page_id`),
  KEY `idx_intwordid_scantime` (`intword_id`,`scantime`)
) ENGINE=MyISAM AUTO_INCREMENT=51704992 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-07-05 21:45:00
