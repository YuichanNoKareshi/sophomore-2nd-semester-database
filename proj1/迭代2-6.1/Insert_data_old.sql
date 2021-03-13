-- 插入department
insert into department VALUES ('内科',1);
insert into department VALUES ('外科',2);
insert into department VALUES ('儿科',3);
insert into department VALUES ('妇科',4);
insert into department VALUES ('眼科',5);
insert into department VALUES ('耳鼻喉科',6);
insert into department VALUES ('口腔科',7);
insert into department VALUES ('皮肤科',8);
insert into department VALUES ('骨科',9);
insert into department VALUES ('消化内科',10);
insert into department VALUES ('泌尿内科',11);
insert into department VALUES ('血液科',12);


-- 插入clinic
drop procedure if exists insert_clinic;
create procedure insert_clinic()
BEGIN
		DECLARE i int;
		DECLARE j int;
		set i = 0;
		while i<36 do
		set j = i+1;
		insert into clinic VALUES (j,(((i-1)/3)+1));
		set i = i+1;
		end while;
	
END;

call insert_clinic();

-- 产生随机字符串
drop function if exists rand_string;
CREATE  FUNCTION `rand_string`(n INT) RETURNS varchar(255) DETERMINISTIC
BEGIN
    DECLARE chars_str varchar(100) DEFAULT 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    DECLARE return_str varchar(255) DEFAULT '';
    DECLARE i INT DEFAULT 0;
    WHILE i < n DO
        SET return_str = concat(return_str,substring(chars_str , FLOOR(1 + RAND()*62 ),1));
        SET i = i +1;
    END WHILE;
    RETURN return_str;
END;

-- 产生随机具体数目个数数字
drop function if exists rand_num;
CREATE  FUNCTION `rand_num`(n INT) RETURNS varchar(255) DETERMINISTIC
BEGIN
    DECLARE chars_str varchar(100) DEFAULT '0123456789';
    DECLARE return_str varchar(255) DEFAULT '';
    DECLARE i INT DEFAULT 0;
    WHILE i < n DO
        SET return_str = concat(return_str,substring(chars_str , FLOOR(1 + RAND()*10 ),1));
        SET i = i +1;
    END WHILE;
    RETURN return_str;
END;

-- 插入医生
drop procedure if exists insert_doctor;
create procedure insert_doctor()
BEGIN
		DECLARE i int;
		DECLARE firstname VARCHAR(100) DEFAULT '';
		set i = 1;
		while i<101 do
		set firstname =  rand_string(5);
		insert into doctor VALUES (i,firstname,floor(RAND()*36+1));
		set i = i+1;
		end while;
	
END;

call insert_doctor();

-- 插入time_list

insert into time_list VALUES (1,'Monday 08:00-10:00');
insert into time_list VALUES (2,'Monday 10:00-12:00');
insert into time_list VALUES (3,'Monday 14:00-16:00');
insert into time_list VALUES (4,'Monday 16:00-18:00');
insert into time_list VALUES (5,'Monday 18:00-20:00');
insert into time_list VALUES (6,'Tuesday 08:00-10:00');
insert into time_list VALUES (7,'Tuesday 10:00-12:00');
insert into time_list VALUES (8,'Tuesday 14:00-16:00');
insert into time_list VALUES (9,'Tuesday 16:00-18:00');
insert into time_list VALUES (10,'Tuesday 18:00-20:00');
insert into time_list VALUES (11,'Wednesday 08:00-10:00');
insert into time_list VALUES (12,'Wednesday 10:00-12:00');
insert into time_list VALUES (13,'Wednesday 14:00-16:00');
insert into time_list VALUES (14,'Wednesday 16:00-18:00');
insert into time_list VALUES (15,'Wednesday 18:00-20:00');
insert into time_list VALUES (16,'Thursday 08:00-10:00');
insert into time_list VALUES (17,'Thursday 10:00-12:00');
insert into time_list VALUES (18,'Thursday 14:00-16:00');
insert into time_list VALUES (19,'Thursday 16:00-18:00');
insert into time_list VALUES (20,'Thursday 18:00-20:00');
insert into time_list VALUES (21,'Friday 08:00-10:00');
insert into time_list VALUES (22,'Friday 10:00-12:00');
insert into time_list VALUES (23,'Friday 14:00-16:00');
insert into time_list VALUES (24,'Friday 16:00-18:00');
insert into time_list VALUES (25,'Friday 18:00-20:00');

-- 插入time_slot

drop procedure if exists insert_timeslot;
create procedure insert_timeslot()
BEGIN
		DECLARE theKey int;
		DECLARE i int;
		DECLARE j int;
		DECLARE docid int;
		set i = 1;
		set theKey = 1;
		while i<37 do
			set j = 1;
			while j<26 do
			(select doc_id into docid from doctor  where doctor.clinic_id=i order by rand( ) limit 1);
			insert into time_slot VALUES (theKey,i,j,docid,1);
			set theKey = theKey+1;
			set j = j+1;
			end while;
		set i = i+1;
		end while;
	
END;

call insert_timeslot();

-- 插入patient，user_info
drop procedure if exists insert_patient;
create procedure insert_patient()
BEGIN
		DECLARE i int;
		DECLARE pname VARCHAR(255) DEFAULT '';
		DECLARE pgender VARCHAR(100) DEFAULT '';
		DECLARE pbirthday DATE;
		DECLARE isadmin int;
		DECLARE username VARCHAR(255) DEFAULT '';
		set i = 101;
		while i<100001 do
		set pname =  rand_string(6);
		if(i%2=0) then
			set pgender = "man";
		ELSE 
			set pgender = "woman";
		end if;
		if(i%100 = 0) THEN
			set isadmin = 1;
		ELSE
			set isadmin = 0;
		end if;
		select date(from_unixtime(
			unix_timestamp('1950-01-01') 
			+ floor(
			rand() * ( unix_timestamp('2018-08-08') - unix_timestamp('1950-01-01') + 1 )
			)
		)) into pbirthday;
		set username = concat("user",i);
		insert into patient VALUES (i,pname,pgender,pbirthday,rand_num(6),"No address");
		insert into user_info values (i,username,rand_string(4),1,isadmin);
		set i = i+1;
		end while;
	
END;

call insert_patient();

-- 插入appointment

drop procedure if exists insert_appointment;
create procedure insert_appointment()
BEGIN
	DECLARE i int;
	DECLARE adate VARCHAR(255);
	DECLARE bdate VARCHAR(255);
	DECLARE random_time_slot_id int(11);
	DECLARE timeId int(11);
	set i = 1;
	while i<100001 do
		if i < 70000 then
			select date(from_unixtime(
				unix_timestamp('2015-01-01') 
				+ floor(
				rand() * ( unix_timestamp('2019-06-05') - unix_timestamp('2015-01-01') + 1 )
				)
			)) into adate;
		select date_format(adate,'%W') into bdate;
		while bdate="Saturday" or bdate="Sunday" do
				select date(from_unixtime(
					unix_timestamp('2015-01-01') 
					+ floor(
					rand() * ( unix_timestamp('2019-06-05') - unix_timestamp('2015-01-01') + 1 )
					)
				)) into adate;
				select date_format(adate,'%W') into bdate;
		end while;
		set random_time_slot_id = floor(RAND()*900+1);
		select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
		if bdate =  "Monday" THEN
			while timeId > 5 do
			set random_time_slot_id = floor(RAND()*900+1);
			select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
			end while;
		ELSEIF bdate = "Tuesday" THEN
			while timeId > 10 or timeId < 6 do
			set random_time_slot_id = floor(RAND()*900+1);
			select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
			end while;
		ELSEIF bdate = "Wednesday" THEN
			while timeId > 15 or timeId < 11 do
			set random_time_slot_id = floor(RAND()*900+1);
			select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
			end while;
		ELSEIF bdate = "Thursday" THEN
			while timeId > 20 or timeId < 16 do
			set random_time_slot_id = floor(RAND()*900+1);
			select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
			end while;
		ELSEIF bdate = "Friday" THEN
			while timeId < 21 do
			set random_time_slot_id = floor(RAND()*900+1);
			select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
			end while;
		ELSE
			set timeId = timeId;
		end if;
	insert into appointment VALUES (i,floor(RAND()*99900+1+100),random_time_slot_id,adate,1,floor(RAND()*100+1));
	ELSE
	select date(from_unixtime(
				unix_timestamp('2019-06-06') 
				+ floor(
				rand() * ( unix_timestamp('2020-06-05') - unix_timestamp('2019-06-06') + 1 )
				)
			)) into adate;
		select date_format(adate,'%W') into bdate;
		while bdate="Saturday" or bdate="Sunday" do
				select date(from_unixtime(
					unix_timestamp('2019-06-06') 
					+ floor(
					rand() * ( unix_timestamp('2020-06-05') - unix_timestamp('2019-06-06') + 1 )
					)
				)) into adate;
				select date_format(adate,'%W') into bdate;
		end while;
		set random_time_slot_id = floor(RAND()*900+1);
		select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
		if bdate =  "Monday" THEN
			while timeId > 5 do
			set random_time_slot_id = floor(RAND()*900+1);
			select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
			end while;
		ELSEIF bdate = "Tuesday" THEN
			while timeId > 10 or timeId < 6 do
			set random_time_slot_id = floor(RAND()*900+1);
			select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
			end while;
		ELSEIF bdate = "Wednesday" THEN
			while timeId > 15 or timeId < 11 do
			set random_time_slot_id = floor(RAND()*900+1);
			select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
			end while;
		ELSEIF bdate = "Thursday" THEN
			while timeId > 20 or timeId < 16 do
			set random_time_slot_id = floor(RAND()*900+1);
			select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
			end while;
		ELSEIF bdate = "Friday" THEN
			while timeId < 21 do
			set random_time_slot_id = floor(RAND()*900+1);
			select time_id into timeId from time_slot where time_slot_id = random_time_slot_id;
			end while;
		ELSE
			set timeId = timeId;
		end if;
	insert into appointment VALUES (i,floor(RAND()*99900+1+100),random_time_slot_id,adate,0,0);
	end if;
	set i = i+1;
	end while;
END;

call insert_appointment();

-- 插入appointment_slot

drop procedure if exists insert_appointmentSlot;
create procedure insert_appointmentSlot()
BEGIN
	DECLARE i int;
	DECLARE timeslotId int;
	DECLARE adate VARCHAR(255);
	set i = 70000;
	while i <100001 do
	select time_slot_id,date into timeslotId,adate from appointment where id = i;
	IF EXISTS	(select * from appointment_slot where time_slot_id=timeslotId and date=adate) THEN
		update appointment_slot set cur_num = cur_num + 1,max_num = cur_num*2
		where time_slot_id=timeslotId and date=adate;
	ELSE
		insert into appointment_slot VALUES (timeslotId,adate,2,1);
	end if;
	set i = i+1;
	end WHILE;
END;

call insert_appointmentSlot();

-- 更新最大个数

drop procedure if exists update_maxnum;
create procedure update_maxnum()
BEGIN
	DECLARE i int;
	select MAX(max_num) into i from appointment_slot;
	update appointment_slot SET max_num = i*10;
END;

call update_maxnum();