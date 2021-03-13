create PROCEDURE Doc_All_timeSlot(in doc_id VARCHAR(255)) -- 找出某一个医生的所有时间段
BEGIN
		select T.clinic_id,T.time,T.cur_num,T.max_num,T.isopen
		from time_slot as T
		where T.doc_id = doc_id;
END;

create PROCEDURE Doc_timeSlot_info(in doc_id VARCHAR(255),in _time VARCHAR(255)) -- 根据医生与时间段返回该段信息
BEGIN
		select T.clinic_id,T.cur_num,T.max_num,T.isopen
		from time_slot as T
		where T.doc_id = doc_id and T.time = _time;
END;


create PROCEDURE update_timeslot_status(in d_id varchar(255),in _time VARCHAR(255),in num_change int(11))
BEGIN
	update time_slot AS T set T.cur_num = T.cur_num + num_change
	where T.time = _time and T.doc_id = d_id;
end;

-- 病人输入时间，科室，医生名查询余量
CREATE FUNCTION `GetRemainNum`(aim_time VARCHAR(255),aim_dept_name VARCHAR(255),aim_doc_name VARCHAR(255)) RETURNS int(11) deterministic
begin 
    DECLARE ret INT;
    SELECT max_num - cur_num
		FROM 
		  clinic	
		  NATURAL JOIN department 
		  NATURAL JOIN doctor 
		  NATURAL JOIN time_slot
		WHERE time = aim_time AND
		      dept_name = aim_dept_name AND 
					doc_name = aim_doc_name AND 
					isopen = 1
		INTO ret;
    RETURN ret;
END;

-- 病人输入id，时间，评分更新评分
CREATE PROCEDURE `setGrade`(aim_p_id INT,aim_time VARCHAR(255),grade INT)
BEGIN 

  UPDATE appointment  
  SET doc_grade = grade
	WHERE patient_id = aim_p_id 
	      AND time_slot_id IN (
				SELECT time_slot_id
				FROM time_slot
				WHERE time = aim_time
				);
END;

-- 病人修改预约状态
CREATE PROCEDURE `updateIsFinished`(aim_p_id INT,aim_time VARCHAR(255))
BEGIN 
  UPDATE appointment  SET isFinished = 1
	WHERE patient_id = aim_p_id 
	      AND time_slot_id IN (
				SELECT time_slot_id
				FROM time_slot
				WHERE time = aim_time
				);
END;




-- 管理员根据科室和时间段管理门诊是否开放
CREATE PROCEDURE `change_openstatus`(in clinic_id varchar(255),in _time VARCHAR(255), in `isopen` tinyint(1))
BEGIN 
  UPDATE time_slot as t  SET t.isopen = isopen
  WHERE t.clinic_id = clinic_id and t.time = _time;
END;

-- 管理员更改医生所负责的科室 //医生里面没有department这个属性，只有clinic_id
CREATE PROCEDURE `change_dept`(in `doc_id` varchar(255), in `clinic_id` varchar(255))
BEGIN 
	UPDATE doctor as d  SET d.clinic_id = clinic_id
	WHERE d.doc_id = doc_id;
END;

-- 修改医生clinic之后，将time_slot中doc_id设置为NULL，删除appointment中该医生所对应time_slot的预约
CREATE TRIGGER change_dept_tri AFTER UPDATE ON doctor
FOR EACH ROW
BEGIN
  DELETE FROM appointment
 	WHERE appointment.time_slot_id IN
 	(
	 SELECT time_slot_id
	 FROM time_slot AS ti
	 WHERE ti.doc_id = OLD.doc_id
	);
	UPDATE time_slot SET time_slot.doc_id = null
 	WHERE time_slot.doc_id = OLD.doc_id;
END;

-- 管理员更改某个时间段的最大预约人数
CREATE PROCEDURE `change_maxnum`(in clinic_id varchar(255),in _time VARCHAR(255), in `max_num` int(11))
BEGIN 
  UPDATE time_slot as t  SET t.max_num = max_num
  WHERE t.clinic_id = clinic_id and t.time = _time;
END;