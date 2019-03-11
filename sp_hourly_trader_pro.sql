DROP PROCEDURE IF EXISTS sp_hourly_trader_pro;
CREATE PROCEDURE sp_hourly_trader_pro(in p_job_ymd date, in p_job_hh char(2),p_last_mat_no int)
BEGIN
  #declare variable
  DECLARE v_last_job_time,v_last_data_time timestamp;
  DECLARE v_last_mat_no, v_max_mat_no int;
  DECLARE v_job_done_yn varchar(1);

    # 매도/매수 수익률과 수량등을 보여주는 데이터는 청산이 되야 가능하므로 청산에서 가져온다.
    # 매도 부터 넣는다.
        INSERT into daily_trader_pro_tbl
        (ymd, trader_no, pro_code, trade_cnt, sell_qty,sell_cnt, sell_prf_rate, pls_amt) 
        SELECT ymd,
               trader_no,
               est.pro_code,
               count(*) AS trade_cnt,
               sum(est.stl_qty) AS sell_qty,
               count(*) as sell_cnt,
               sum(est.prf_rate) AS sell_rate,
               sum(pls_amt) AS stl_amt
          FROM ent_stl_mat_tbl AS est
         WHERE  mat_no > p_last_mat_no
               AND ymd =p_job_ymd
               AND bsns_time =p_job_hh
               AND est.ent_sby_cd = 1
        GROUP BY ymd, trader_no,est.pro_code
        ON DUPLICATE KEY UPDATE  trade_cnt=trade_cnt+values(trade_cnt), sell_qty=sell_qty+values(sell_qty), sell_cnt=sell_cnt+values(sell_cnt),
                                sell_prf_rate=sell_prf_rate+values(sell_prf_rate), pls_amt=pls_amt+values(pls_amt);

    # 매수를 넣는다.
        INSERT into daily_trader_pro_tbl
        (ymd, trader_no, pro_code, trade_cnt, buy_qty,buy_cnt, buy_prt_rate, pls_amt) 
        SELECT ymd,
               trader_no,
               est.pro_code,
               count(*) AS trade_cnt,
               sum(est.stl_qty) AS buy_qty,
               count(*) as buy_cnt,
               sum(est.prf_rate) AS buy_prt_rate,
               sum(pls_amt) AS stl_amt
          FROM ent_stl_mat_tbl AS est
         WHERE  mat_no > p_last_mat_no
               AND ymd =p_job_ymd
               AND bsns_time =p_job_hh
               AND est.ent_sby_cd = 2
        GROUP BY ymd, trader_no,est.pro_code
        ON DUPLICATE KEY UPDATE  trade_cnt=trade_cnt+values(trade_cnt), buy_qty=buy_qty+values(buy_qty), buy_cnt=buy_cnt+values(buy_cnt),
                                buy_prt_rate=buy_prt_rate+values(buy_prt_rate), pls_amt=pls_amt+values(pls_amt);

END;
