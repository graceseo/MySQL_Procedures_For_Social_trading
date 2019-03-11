DROP PROCEDURE IF EXISTS sp_hourly_trader_time;
CREATE PROCEDURE sp_hourly_trader_time(in p_kor_date_time timestamp, in p_job_ymd date )
BEGIN
  #declare variable
  DECLARE v_last_mat_no, v_max_mat_no int;
  DECLARE v_range_no,v_kor_time tinyint;
  DECLARE v_range_name varchar(6);
  -- 주거래 시간은 한국 시간 기준.

  # 받아온 영업날짜와시간을 가지고 현재 한국 시간을 찾아서 주거래 시간을 찾는다.
    select kor_time into v_kor_time from stock_sts_static_db.bsns_date_mat_tbl where bsns_date=p_kor_date_time;
  
  # 수집될 데이터의 시간을 가지고 거래시간 테이블에서 번호와 이름을 가져온다. 한시간마다 돌기 때문에 어차피 한 row만 나온다. 마지막 시간 에서 1시간을 빼야 됨.
    select range_no,range_name into v_range_no,v_range_name
    from stock_sts_static_db.time_range_detail_tbl where range_time=v_kor_time; -- 기준테이블은 되도록 static에서 가져온다.

    INSERT INTO daily_trader_time_tbl(ymd,
                                      range_no,
                                      trader_no,
                                      range_name,
                                      trade_cnt)
       SELECT ymd,
              v_range_no,
              trader_no,
              v_range_name,
              count(*)
         FROM cns_tbl  -- 주거래시간은 전체 체결테이블에서 가져옴.
        WHERE   ymd = p_job_ymd
              AND cns_time=v_kor_time --  해당 영업일의 한국 주거래 시간
       GROUP BY ymd, trader_no
          ON DUPLICATE KEY UPDATE trade_cnt = trade_cnt +values(trade_cnt);

END;