DROP PROCEDURE IF EXISTS sp_hourly_job;
CREATE PROCEDURE sp_hourly_job()
BEGIN
  #declare variable
  DECLARE v_last_job_time,v_last_data_time timestamp;
  DECLARE v_last_mat_no, v_max_mat_no int;
  DECLARE v_job_done_yn varchar(1);
  DECLARE v_job_yyyy date;
  DECLARE v_job_hh char(2);
  
    # ������ �۾��ð� �� ��ȣ Ȯ��
  SELECT last_job_time, last_data_time, last_mat_no, job_done_yn into  v_last_job_time, v_last_data_time, v_last_mat_no, v_job_done_yn
  FROM last_job_time;

   ## job ����Ǿ��� ��¥�� �ð� ����.
  set v_job_yyyy=date(adddate(v_last_data_time, INTERVAL 1 HOUR));
  set v_job_hh=hour(adddate(v_last_data_time,interval 1 HOUR));
  
select v_job_yyyy,v_job_hh;
   # û���Ī ���̺��� '������ ��Ī��ȣ' ������ ��ȣ�� û������ '������ ������ �ð�'���� +1�ð� �� ������ ã��. 
  select max(stl_cns_idx) into v_max_mat_no 
  from ent_stl_mat_tbl 
  where stl_cns_idx>v_last_mat_no and ymd=v_job_yyyy and cns_time=v_job_hh;


  # û�굥���Ͱ� ������ job���� 
  if v_max_mat_no is not null then

    ## �������ν��� ȣ��
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
 
 # û�굥���Ͱ� ������ job���� 
  elseif v_max_mat_no is null then
    # �ش�����, �ش� �ð��� �����Ͱ� ������ �ð��� +1�ϰ�  job�� '��Ī��ȣ'�� ������ ��ȣ�� �����Ѵ�.
    update last_job_time set last_job_time=curdate(),last_data_time=adddate(v_last_data_time,INTERVAL 1 HOUR),last_mat_no=v_last_mat_no,job_done_yn='Y';  
    
  end if;

END;

