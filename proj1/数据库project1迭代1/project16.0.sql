/*
Navicat MySQL Data Transfer

Source Server         : mysql
Source Server Version : 50725
Source Host           : localhost:3306
Source Database       : project

Target Server Type    : MYSQL
Target Server Version : 50725
File Encoding         : 65001

Date: 2020-05-08 10:41:35
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for appointment
-- ----------------------------
DROP TABLE IF EXISTS `appointment`;
CREATE TABLE `appointment` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `patient_id` varchar(255) NOT NULL,
  `time_slot_id` int(11) DEFAULT NULL,
  `date` varchar(255) NOT NULL, -- 预约的是哪一天的此时间段 
  `isFinished` tinyint(1) DEFAULT NULL,
  `doc_grade` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `time_slot` (`time_slot_id`),
  CONSTRAINT `time_slot` FOREIGN KEY (`time_slot_id`) REFERENCES `time_slot` (`time_slot_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for clinic
-- ----------------------------
DROP TABLE IF EXISTS `clinic`;
CREATE TABLE `clinic` (
  `clinic_id` varchar(255) NOT NULL,
  `dept_id` int(11) NOT NULL,
  PRIMARY KEY (`clinic_id`),
  KEY `dept` (`dept_id`),
  CONSTRAINT `dept` FOREIGN KEY (`dept_id`) REFERENCES `department` (`dept_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for department
-- ----------------------------
DROP TABLE IF EXISTS `department`;
CREATE TABLE `department` (
  `dept_name` varchar(255) DEFAULT NULL,
  `dept_id` int(11) NOT NULL,
  PRIMARY KEY (`dept_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for doctor
-- ----------------------------
DROP TABLE IF EXISTS `doctor`;
CREATE TABLE `doctor` (
  `doc_id` varchar(255) NOT NULL,
  `doc_name` varchar(255) NOT NULL,
  `clinic_id` varchar(255) NOT NULL,
  PRIMARY KEY (`doc_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for patient
-- ----------------------------
DROP TABLE IF EXISTS `patient`;
CREATE TABLE `patient` (
  `patient_id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `gender` char(255) NOT NULL,
  `birthday` datetime NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`patient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for time_list
-- ----------------------------
DROP TABLE IF EXISTS `time_list`;
CREATE TABLE `time_list` (
  `time_id` int(11) NOT NULL, -- 给每个规定的时间段编号 
  `time` varchar(255) DEFAULT NULL, -- 从几点到几点，周几（一周一个轮回） 
  PRIMARY KEY (`time_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for time_slot，time_slot记录时间段、门诊、医生三者的对应关系
-- ----------------------------
DROP TABLE IF EXISTS `time_slot`;
CREATE TABLE `time_slot` (
  `time_slot_id` int(11) NOT NULL, -- 给每个time_slot编号
  `clinic_id` varchar(255) NOT NULL,
  `time_id` int(11) DEFAULT NULL,
  `doc_id` varchar(255) DEFAULT NULL,
  `isopen` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`time_slot_id`),
  KEY `outpatient` (`clinic_id`,`doc_id`),
  KEY `clinic` (`doc_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for appointment_slot，appointment_slot记录每天的预约人数
-- ----------------------------
DROP TABLE IF EXISTS `appointment_slot`;
CREATE TABLE `appointment_slot` (
  `time_slot_id` int(11) NOT NULL, -- 给每个time_slot编号
  `date` varchar(255) NOT NULL, -- 预约的是哪一天的此时间段 
  `max_num` int(11) DEFAULT NULL,
  `cur_num` int(11) DEFAULT NULL,
  PRIMARY KEY (`time_slot_id`,`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for user_info
-- ----------------------------
DROP TABLE IF EXISTS `user_info`;
CREATE TABLE `user_info` (
  `id` varchar(255) NOT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` int(11) NOT NULL,
  `isadmin` int(11) NOT NULL,
  PRIMARY KEY (`username`),
  KEY `aid` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
