DROP PROCEDURE IF EXISTS sp_hourly_job;
CREATE PROCEDURE sp_hourly_job()
BEGIN
  #declare variable
  DECLARE v_last_job_time,v_last_data_time timestamp;
  DECLARE v_last_mat_no, v_max_mat_no int;
  DECLARE v_job_done_yn varchar(1);
  DECLARE v_job_yyyy date;
  DECLARE v_job_hh char(2);
  
    # 마지막 작업시간 및 번호 확인
  SELECT last_job_time, last_data_time, last_mat_no, job_done_yn into  v_last_job_time, v_last_data_time, v_last_mat_no, v_job_done_yn
  FROM last_job_time;

   ## job 실행되야할 날짜와 시간 저장.
  set v_job_yyyy=date(adddate(v_last_data_time, INTERVAL 1 HOUR));
  set v_job_hh=hour(adddate(v_last_data_time,interval 1 HOUR));
  
select v_job_yyyy,v_job_hh;
   # 청산매칭 테이블에서 '마지막 매칭번호' 이후의 번호와 청산일이 '마지막 데이터 시간'보다 +1시간 인 데이터 찾기. 
  select max(stl_cns_idx) into v_max_mat_no 
  from ent_stl_mat_tbl 
  where stl_cns_idx>v_last_mat_no and ymd=v_job_yyyy and cns_time=v_job_hh;


  # 청산데이터가 있으면 job실행 
  if v_max_mat_no is not null then

    ## Call procedures!!
    call sp_hourly_trader_pro(v_job_yyyy,v_job_hh,v_last_mat_no);
    call sp_hourly_trader_time(v_job_yyyy,v_job_hh,v_last_mat_no);
    call sp_hourly_trader_patt(v_job_yyyy,v_job_hh,v_last_mat_no);
    call sp_hourly_trader_tot(v_job_yyyy,v_job_hh,v_last_mat_no);
    call sp_daily_trader_tot(v_job_yyyy,v_job_hh,v_last_mat_no);
    call sp_hourly_trader_social(v_job_yyyy,v_job_hh,v_last_mat_no);
    call sp_daily_trader_social(v_job_yyyy,v_job_hh,v_last_mat_no);
    call sp_hourly_pro(v_job_yyyy,v_job_hh,v_last_mat_no);
    call sp_daily_pro(v_job_yyyy,v_job_hh,v_last_mat_no);

    update last_job_time set last_job_time=curdate(),last_data_time=adddate(v_last_data_time,INTERVAL 1 HOUR),last_mat_no=v_max_mat_no,job_done_yn='Y';
 
 # 청산데이터가 없으면 job종료 
  elseif v_max_mat_no is null then
    # 해당일자, 해당 시간에 데이터가 없으면 시간은 +1하고  job의 '매칭번호'를 기존의 번호로 저장한다.
    update last_job_time set last_job_time=curdate(),last_data_time=adddate(v_last_data_time,INTERVAL 1 HOUR),last_mat_no=v_last_mat_no,job_done_yn='Y';  
    
  end if;

END;

