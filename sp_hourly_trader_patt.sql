DROP PROCEDURE IF EXISTS sp_hourly_trader_patt;
CREATE PROCEDURE sp_hourly_trader_patt(in p_job_ymd date, in p_job_hh char(2),p_last_mat_no int)
BEGIN
  #declare variablestl_cns_idx
  DECLARE v_last_job_time,v_last_data_time timestamp;
  DECLARE v_last_mat_no, v_max_mat_no int;
  DECLARE v_job_done_yn varchar(1);
  DECLARE v_1_execed,v_1_under, v_2_execed,v_2_under, v_3_execed,v_3_under, v_4_execed,v_4_under, v_5_execed,v_5_under, v_6_execed,v_6_under, v_7_execed,v_7_under, v_8_execed,v_8_under, v_9_execed,v_9_under decimal(7,1);

# 어드민에서 입력한 매매패턴 테이블을 가져와서 트레이더들의 그날의 패턴을 누적 합계낸다.

    # 패턴 기준테이블의 데이터를 담는다.
      select 
        max(1_execed),max(1_under),max(2_execed),max(2_under),max(3_execed),max(3_under),
        max(4_execed),max(4_under),max(5_execed),max(5_under),max(6_execed),max(6_under),
        max(7_execed),max(7_under),max(8_execed),max(8_under),max(9_execed),max(9_under) 
        into v_1_execed,v_1_under, v_2_execed,v_2_under, v_3_execed,v_3_under, v_4_execed,v_4_under, 
        v_5_execed,v_5_under, v_6_execed,v_6_under, v_7_execed,v_7_under, v_8_execed,v_8_under, v_9_execed,v_9_under
      from 
        (select 
        (case idx_no when 1 then exceed else null end) as 1_execed ,(case idx_no when 1 then under else null end) as 1_under,
        (case idx_no when 2 then exceed else null end) as 2_execed ,(case idx_no when 2 then under else null end) as 2_under,
        (case idx_no when 3 then exceed else null end) as 3_execed ,(case idx_no when 3 then under else null end) as 3_under,
        (case idx_no when 4 then exceed else null end) as 4_execed ,(case idx_no when 4 then under else null end) as 4_under,
        (case idx_no when 5 then exceed else null end) as 5_execed ,(case idx_no when 5 then under else null end) as 5_under,
        (case idx_no when 6 then exceed else null end) as 6_execed ,(case idx_no when 6 then under else null end) as 6_under,
        (case idx_no when 7 then exceed else null end) as 7_execed ,(case idx_no when 7 then under else null end) as 7_under,
        (case idx_no when 8 then exceed else null end) as 8_execed ,(case idx_no when 8 then under else null end) as 8_under,
        (case idx_no when 9 then exceed else null end) as 9_execed ,(case idx_no when 9 then under else null end) as 9_under
      from stock_sts_db.sts_dealing_pattern_tbl) as patt;


  # 패턴 기준테이블에서 select해서 넣는다.
        INSERT INTO daily_trader_pattern_tbl
        (ymd, trader_no, lever1, lever2, lever3, peri1, peri2, peri3, qty1, qty2, qty3) 
        select ymd,trader_no,sum(lever1), sum(lever2), sum(lever3), sum(peri1), sum(peri2), sum(peri3), sum(qty1), sum(qty2), sum(qty3)
        from 
         ( select ymd,trader_no,
            case when (abs(et.ent_stl_tic) between v_1_execed+1 and v_1_under) then 1 else 0 end as lever1,
            case when (abs(et.ent_stl_tic) between v_2_execed+1 and v_2_under) then 1 else 0 end as lever2,
            case when (abs(et.ent_stl_tic) between v_3_execed+1 and v_3_under) then 1 else 0 end as lever3,
            case when (et.hold_time between v_4_execed+1 and v_4_under) then 1 else 0 end as peri1,
            case when (et.hold_time between v_5_execed+1 and v_5_under) then 1 else 0 end as peri2,
            case when (et.hold_time between v_6_execed+1 and v_6_under) then 1 else 0 end as peri3,
            case when (et.stl_qty between v_7_execed+1 and v_7_under) then 1 else 0 end as qty1,
            case when (et.stl_qty between v_8_execed+1 and v_8_under) then 1 else 0 end as qty2,
            case when (et.stl_qty between v_9_execed+1 and v_9_under) then 1 else 0 end as qty3
          from  ent_stl_mat_tbl as et 
          where mat_no>p_last_mat_no and ymd=p_job_ymd and bsns_time=p_job_hh
        ) as tot_par group by ymd,trader_no
        ON DUPLICATE KEY UPDATE lever1=lever1+values(lever1),
                                lever2=lever2+values(lever2),
                                lever3=lever3+values(lever3),
                                peri1=peri1+values(peri1),
                                peri2=peri2+values(peri2),
                                peri3=peri3+values(peri3),
                                qty1=qty1+values(qty1),
                                qty2=qty2+values(qty1),
                                qty3=qty3+values(qty1);


END;
