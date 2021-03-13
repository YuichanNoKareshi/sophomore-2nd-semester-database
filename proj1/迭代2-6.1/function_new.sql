DROP FUNCTION IF EXISTS `get_timeslotid`;
CREATE FUNCTION `get_timeslotid`(aim_time VARCHAR(50),aim_doc_name VARCHAR(20)) RETURNS int(11)
begin 
    declare ret INT;
    select C.time_slot_id
		from (select time_slot_id from time_slot 
        natural join (select doc_id from doctor where doc_name=aim_doc_name) as A
        natural join (select time_id from time_list where time=aim_time) AS B) as C
		into ret;
    return ret;
end;

DROP PROCEDURE IF EXISTS `add_Appoint`;
CREATE PROCEDURE `add_Appoint`(`p_id` VARCHAR(10),`dept_name` VARCHAR(50),`aim_date` VARCHAR(50),aim_time VARCHAR(50),`doc_name` VARCHAR(50))
BEGIN
  DECLARE can_add INT DEFAULT 0;
 DECLARE tmp_time_slot_id INT DEFAULT 0;
 SELECT GetRemainNum(aim_date,aim_time,dept_name,doc_name) into can_add;
  SELECT get_timeslotid(aim_time,doc_name) into tmp_time_slot_id;
 IF can_add > 0 THEN
--  添加appointment
  INSERT INTO appointment (patient_id,time_slot_id,date,isFinished,doc_grade)
  VALUES (p_id,tmp_time_slot_id,aim_date,0,0);
 UPDATE appointment_slot as Y SET cur_num = cur_num + 1
 WHERE Y.date = aim_date AND Y.time_slot_id = tmp_time_slot_id;
  ELSE
 SELECT 2 INTO can_add;  -- 什么都不做
  END IF;

END;

DROP  PROCEDURE  IF  EXISTS  `Doc_All_timeSlot`;
CREATE  PROCEDURE  `Doc_All_timeSlot`(in  aim_doc_id  VARCHAR(255))
BEGIN
     select  clinic_id,time,isopen
     from  (time_list  NATURAL  JOIN  ((SELECT  *  FROM  time_slot  WHERE  doc_id  =  aim_doc_id)  as  B));
END;

--  Procedure  structure  for  Doc_timeSlot_info
DROP  PROCEDURE  IF  EXISTS  `Doc_timeSlot_info`;
CREATE  PROCEDURE  `Doc_timeSlot_info`(in  aim_doc_id  VARCHAR(255),in  aim_time  VARCHAR(255),in  aim_date  VARCHAR(255))
BEGIN
      select  cur_num,max_num,date,time
      from  (select  *  from  time_slot  WHERE  doc_id=aim_doc_id)  as  A  natural  join  (SELECT  *  FROM  time_list  WHERE  time=aim_time)  as  B  natural  join  (SELECT  *  FROM  appointment_slot  WHERE  date  =  aim_date)  as  T;
END;


DROP  PROCEDURE  IF  EXISTS  `update_timeslot_status`;
CREATE  PROCEDURE  `update_timeslot_status`(in  aim_doc_id  varchar(255),in  aim_time_id  int(11),in  aim_date  VARCHAR(255),in  num_change  int(11))
BEGIN
        update  appointment_slot  AS  A  set  A.cur_num  =  A.cur_num  +  num_change
        where  A.date  =  aim_date  and  EXISTS
        (
                select  *
                from  time_slot  as  T
                where  T.doc_id  =  aim_doc_id  and  T.time_id  =  aim_time_id  and  T.time_slot_id  =  A.time_slot_id
        );
end;



DROP  PROCEDURE  IF  EXISTS  `setGrade`;
CREATE PROCEDURE `setGrade`(p_id VARCHAR(20),p_date VARCHAR(50),p_time VARCHAR(50),grade INT)
BEGIN 
  UPDATE appointment as A SET A.doc_grade = grade
	WHERE A.patient_id = p_id 
	      and A.date = p_date
	      and A.time_slot_id in (
				SELECT B.time_slot_id
				FROM time_slot as B 
				natural join 
				     (select time_id from time_list where time = p_time ) as C
				);
END;

DROP  FUNCTION  IF  EXISTS  `GetRemainNum`;
CREATE FUNCTION `GetRemainNum`(aim_date VARCHAR(50),aim_time VARCHAR(50),aim_dept_name VARCHAR(20),aim_doc_name VARCHAR(20)) RETURNS int(11)
begin 
    declare ret INT;
    select F.max_num - F.cur_num
    from 
     appointment_slot as F 
    where F.date = aim_date and F.time_slot_id = 
    (
     select time_slot_id
     from time_slot as E
     where E.time_id = (select time_id from time_list where time = aim_time)
     and E.doc_id = (select doc_id from doctor where doc_name = aim_doc_name)
     and E.clinic_id in (select clinic_id from clinic where 
       dept_id = (
       select dept_id from department where dept_name = aim_dept_name))
     and E.isopen = 1
    )
    into ret;
    return ret;
end;

-- 用natural join实现 不是最优版本
DROP  FUNCTION  IF  EXISTS  `GetRemainNum2`;
CREATE FUNCTION `GetRemainNum2`(aim_date VARCHAR(50),aim_time VARCHAR(50),aim_dept_name VARCHAR(20),aim_doc_name VARCHAR(20)) RETURNS int(11)
begin 

declare ret INT;
    select (F.max_num - F.cur_num) * D.isopen
  from 
    clinic as A
    natural join (select dept_id from department where dept_name =  aim_dept_name) as B
    natural join (select doc_id, clinic_id from doctor where doc_name = aim_doc_name) as C
   natural join time_slot as D
   natural join (select time_id from time_list where time = aim_time) as E
    natural join (select * from appointment_slot where date = aim_date) as F
  into ret;
    return ret;
end;

DROP  PROCEDURE  IF  EXISTS  `change_maxnum`;
CREATE PROCEDURE `change_maxnum`(in clinic_id varchar(255),in time varchar(255), in date varchar(255), in `max_num` int(11))
BEGIN 
  UPDATE appointment_slot as a SET a.max_num = max_num
  WHERE a.date = date and a.time_slot_id = 
  (select time_slot_id from time_slot as ts 
  where ts.clinic_id = clinic_id 
  and ts.time_id = 
  (select time_id from time_list as tl where tl.time = time)
  );
END;

drop PROCEDURE if EXISTS `updateIsFinished`; -- 新的update
CREATE PROCEDURE `updateIsFinished`(aim_p_id INT,aim_time VARCHAR(255),aim_date varchar(255) )
BEGIN 
 update  appointment set isFinished=1
 WHERE patient_id = aim_p_id and date=aim_date
       AND time_slot_id IN (
    SELECT time_slot_id
    FROM time_slot natural join time_list
    WHERE time = aim_time 
    );
END;

drop PROCEDURE if EXISTS `moveToFinished`; -- 将所有的移过去
CREATE PROCEDURE `moveToFinished`()
BEGIN 
	declare done int default 0;
	declare pid VARCHAR(255) default '0';
  declare timeslotid INT(11) DEFAULT 0;
	declare date VARCHAR(255) default '0';
	declare grade INT default 0; 
  declare mc cursor for select patient_id,time_slot_id,date, doc_grade from appointment where isFinished=1;
	declare continue handler for not found set done =1;
	while done != 1 do
		fetch mc into pid,timeslotid,date,grade;
		if done!=1 then
			insert into appointment_finish(patien_id,time_slot_id,date,doc_grade) VALUES (pid,timeslotid,date,grade);
		end if;
	end while;
END;

-- 定时刷新
set global event_scheduler=1;
create event move_every_hour
on SCHEDULE EVERY 168 HOUR -- 每周一更新
STARTS '2020-07-04 16:15:00'
on COMPLETION PRESERVE
ENABLE
do call moveToFinished();

-- 管理员根据科室和时间段管理门诊是否开放
drop PROCEDURE if EXISTS `change_openstatus`;
CREATE PROCEDURE `change_openstatus`(in clinic_id varchar(255),in time varchar(255), in `isopen` tinyint(1))
BEGIN 
  UPDATE time_slot as t  SET t.isopen = isopen
  WHERE t.clinic_id = clinic_id and  t.time_id = (select time_id from time_list as tl where tl.time = time);
END;

-- 管理员更改医生所负责的科室 //医生里面没有department这个属性，只有clinic_id
drop PROCEDURE if EXISTS `change_dept`;
CREATE PROCEDURE `change_dept`(in `doc_id` varchar(255), in `clinic_id` varchar(255))
BEGIN 
	UPDATE doctor as d  SET d.clinic_id = clinic_id
	WHERE d.doc_id = doc_id;
END;


drop TRIGGER if EXISTS `change_dept_tri`;
CREATE TRIGGER change_dept_tri AFTER UPDATE ON doctor
FOR EACH ROW
BEGIN
  DELETE FROM appointment
 	WHERE EXISTS
 	(
	 SELECT time_slot_id
	 FROM time_slot AS ti
	 WHERE ti.doc_id = OLD.doc_id and ti.time_slot_id = appointment.time_slot_id
	);
	UPDATE time_slot SET time_slot.doc_id = null
 	WHERE time_slot.doc_id = OLD.doc_id;
END;

-- 管理员更改某个时间段的最大预约人数 
drop PROCEDURE if EXISTS `change_maxnum`;
CREATE PROCEDURE `change_maxnum`(in clinic_id varchar(255),in time varchar(255), in date varchar(255), in `max_num` int(11))
BEGIN 
  UPDATE appointment_slot as a  SET a.max_num = max_num
  WHERE a.date = date and a.time_slot_id = 
  (select time_slot_id from time_slot as ts 
  where ts.clinic_id = clinic_id 
  and ts.time_id = 
  (select time_id from time_list as tl where tl.time = time)
  );
END;