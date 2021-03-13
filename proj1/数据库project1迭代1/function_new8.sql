drop procedure if exists `Doc_All_timeSlot`;
create PROCEDURE Doc_All_timeSlot(in doc_id VARCHAR(255)) -- 找出某一个医生的所有时间段(只是找出time_slot部分，即一周内什么时间段工作)
BEGIN
		select T.clinic_id,T.time,T.isopen
		from (select * from time_slot natural join time_list) as T
		where T.doc_id = doc_id;
END;

drop procedure if exists `Doc_timeSlot_info`;
create PROCEDURE Doc_timeSlot_info(in doc_id VARCHAR(255),in time VARCHAR(255),in date VARCHAR(255)) -- 根据医生与某一具体日期与某一具体时间段返回该段信息
BEGIN
		select T.cur_num,T.max_num,T.date,T.time
		from (select * from time_slot natural join time_list natural join appointment_slot) as T
		where T.doc_id = doc_id and T.time = time and T.date = date;
END;

drop procedure if exists `update_timeslot_status`;
create PROCEDURE update_timeslot_status(in d_id varchar(255),in time_id int(11),in date VARCHAR(255),in num_change int(11))
BEGIN
	update appointment_slot AS A set A.cur_num = A.cur_num + num_change
	where A.date = date and A.time_slot_id in 
	(
		select T.time_slot_id
		from time_slot as T
		where T.doc_id = doc_id and T.time_id = time_id
	);
end;


-- 病人修改预约状态
drop PROCEDURE if EXISTS `updateIsFinished`;
CREATE PROCEDURE `updateIsFinished`(aim_p_id INT,
		aim_time VARCHAR(255),aim_date varchar(255) )
BEGIN 
  UPDATE appointment  SET isFinished = 1
	WHERE patient_id = aim_p_id and date=aim_date
	      AND time_slot_id IN (
				SELECT time_slot_id
				FROM time_slot natural join time_list
				WHERE time = aim_time 
				);
END;




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

-- 修改医生clinic之后，将time_slot中doc_id设置为NULL，删除appointment中该医生所对应time_slot的预约
drop TRIGGER if EXISTS `change_dept_tri`;
CREATE TRIGGER change_dept_tri AFTER UPDATE ON doctor
FOR EACH ROW
BEGIN
  DELETE FROM appointment
 	WHERE isFinished <> 1 and appointment.time_slot_id IN
 	(
	 SELECT time_slot_id
	 FROM time_slot AS ti
	 WHERE ti.doc_id = OLD.doc_id
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

-- 病人输入时间，科室，医生名查询余量，不开放返回0
drop FUNCTION if EXISTS `GetRemainNum`;
CREATE FUNCTION `GetRemainNum`(aim_date VARCHAR(50),aim_time VARCHAR(50),aim_dept_name VARCHAR(20),aim_doc_name VARCHAR(20)) RETURNS int(11)
begin 
    declare ret INT;
    select (F.max_num - F.cur_num) * D.isopen
		from 
		  clinic as A
		  natural join department as B
		  natural join doctor as C
			natural join time_slot as D
			natural join time_list as E
		  natural join appointment_slot as F
		where F.date = aim_date and
		      E.time = aim_time and 
		      B.dept_name =  aim_dept_name and 
					C.doc_name = aim_doc_name
		      into ret;
    return ret;
end;

-- 病人输入id，时间，评分更新评分
drop PROCEDURE if EXISTS `setGrade`;
CREATE PROCEDURE `setGrade`(p_id VARCHAR(20),p_date VARCHAR(50),p_time VARCHAR(50),grade INT)
BEGIN 
  UPDATE appointment as A SET A.doc_grade = grade
	WHERE A.patient_id = p_id 
	      and A.date = p_date
	      and A.time_slot_id in (
				SELECT B.time_slot_id
				FROM time_slot as B natural join time_list as C
				where C.time = p_time
				);
END;

DROP FUNCTION IF EXISTS `get_time_slot_id`;
CREATE FUNCTION `get_time_slot_id`(aim_date VARCHAR(50),aim_time VARCHAR(50),
					aim_dept_name VARCHAR(20),aim_doc_name VARCHAR(20)) RETURNS int(11)
begin 
    declare ret INT;
    select D.time_slot_id
		from 
		  clinic as A
		  natural join department as B
		  natural join doctor as C
			natural join time_slot as D
			natural join time_list as E
		  natural join appointment_slot as F
		where F.date = aim_date and
		      E.time = aim_time and 
		      B.dept_name =  aim_dept_name and 
					C.doc_name = aim_doc_name
		      into ret;
    return ret;
end;

DROP PROCEDURE IF EXISTS `addAppoint`;
CREATE PROCEDURE `addAppoint`(`p_id` VARCHAR(10),`dept_name` VARCHAR(50),`aim_date` VARCHAR(50),aim_time VARCHAR(50),`doc_name` VARCHAR(50))
BEGIN
  DECLARE can_add INT DEFAULT 0;
 DECLARE tmp_time_slot_id INT DEFAULT 0;
 SELECT GetRemainNum(aim_date,aim_time,dept_name,doc_name) into can_add;
  SELECT get_time_slot_id(aim_date,aim_time,dept_name,doc_name) into tmp_time_slot_id;
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