DROP PROCEDURE IF EXISTS sp_hourly_trader_tot;
CREATE PROCEDURE `sp_hourly_trader_tot`(in p_job_ymd date, in p_job_hh char(2),p_last_mat_no int)
BEGIN
  #declare variable
  DECLARE v_last_job_time,v_last_data_time timestamp;
  DECLARE v_last_mat_no, v_max_mat_no int;
  DECLARE v_job_done_yn varchar(1);
-- 0 으로 넣은 값들은 청산과 관련없는 것들.

# 기존에 존재하는 값은 delete하지 않고 그냥 update친다.
insert into hourly_trader_tot_tbl(ymd,
                                                  hh,
                                                  trader_no,
                                                  trade_cnt,
                                                  trade_qty,
                                                  hold_time,
                                                  win_cnt,
                                                  lose_cnt,
                                                  prf_tick,
                                                  loss_tick,
                                                  prf_rate,
                                                  pls_amt,
                                                  win_rate,
                                                  prf_avg_tick,
                                                  loss_avg_tick,
                                                  max_prf_rate,
                                                  max_loss_rate,
                                                  avg_prf_rate,
                                                  mna_trade_cnt,
                                                  max_trade_qty,
                                                  avg_trade_cnt,
                                                  avg_trade_qty,
                                                  avg_hold_time,
                                                  max_loss_tick,
                                                  max_prf_tick,
                                                  prt_tick_cnt,
                                                  loss_tick_cnt)
   SELECT ymd,
          bsns_time,
          trader_no,
          count(*),                                                    -- 매매횟수
          sum(stl_qty), -- 매매수량
          sum(hold_time), -- 보유시간
          sum(prf_yn),                                                -- 이긴 횟수
          sum(CASE prf_yn WHEN 0 THEN 1 ELSE 0 END), -- 진 횟수 
          sum(CASE WHEN ent_stl_tic > 0 THEN ent_stl_tic ELSE 0 END),   -- 수익 틱 
          (sum(CASE WHEN ent_stl_tic < 0 THEN ent_stl_tic ELSE 0 END)), -- 손실틱 
          sum(prf_rate),                                                -- 수익률
          sum(pls_amt),                                                 -- 손익금
          ifnull((sum(prf_yn) * 100) / count(*),0),  -- 승률
          0, -- 시간별 평균 수익틱 
          0,   -- 시간별 평균손실틱
          max(CASE WHEN prf_rate > 0 THEN prf_rate ELSE 0 END), -- 1회 최대수익률
          min(CASE WHEN prf_rate < 0 THEN prf_rate ELSE 0 END), -- 1회 최대손실률
          avg(prf_rate), -- 평균 수익률 
          0, -- 직접 매매횟수//청산이 아닌 전체 직접 매매횟수 
          0, -- 1회 주문최대수량 //청산이 아닌 전체 최대수량 
          count(*), -- 평균매매 횟수는 일간테이블까지는 count나 sum만 하고 하루 이상 데이터를 뽑을땐 avg를 내야함.
          sum(stl_qty)/count(*), -- 평균매매수량
          avg(hold_time), -- 평균보유시간 
          min(case when ent_stl_tic > 0 then ent_stl_tic else 0 end), -- 최대 손실틱
          max(case when ent_stl_tic < 0 then ent_stl_tic else 0 end), -- 최대 수익틱 
          sum(CASE WHEN ent_stl_tic > 0 THEN 1 ELSE 0 END), -- 수익틱 매매건수
          sum(CASE WHEN ent_stl_tic < 0 THEN 1 ELSE 0 END)-- 손실틱 매매건수
     from ent_stl_mat_tbl
    WHERE     mat_no > p_last_mat_no
          AND ymd = p_job_ymd
          AND bsns_time =p_job_hh
   GROUP BY ymd, bsns_time, trader_no
ON DUPLICATE KEY UPDATE ymd =values(ymd), hh =values(hh), trader_no =values(trader_no), 
          trade_cnt =values(trade_cnt), trade_qty =values(trade_qty), 
          hold_time =values(hold_time), win_cnt =values(win_cnt), 
          prf_tick =values(prf_tick), loss_tick =values(loss_tick), 
          prf_rate =values(prf_rate), pls_amt =values(pls_amt), 
          win_rate =values(win_rate),lose_cnt=values(lose_cnt),
          prf_avg_tick =values(prf_avg_tick), loss_avg_tick =values(loss_avg_tick),
          max_prf_rate =values(max_prf_rate), max_loss_rate =values(max_loss_rate), 
          avg_prf_rate =values(avg_prf_rate), mna_trade_cnt =values(mna_trade_cnt), 
          max_trade_qty =values(max_trade_qty), avg_trade_cnt =values(avg_trade_cnt), 
          avg_trade_qty =values(avg_trade_qty), avg_hold_time =values(avg_hold_time),
          max_loss_tick =values(max_loss_tick),max_prf_tick=values(max_prf_tick),
          prt_tick_cnt=values(prt_tick_cnt),loss_tick_cnt=values(loss_tick_cnt);
 
 -- 시간별 평균 수익틱= 틱이 0보다 큰 경우 
    UPDATE hourly_trader_tot_tbl
       SET prf_avg_tick = ifnull((prf_tick/prt_tick_cnt),0)
     WHERE ymd = p_job_ymd
       AND hh = p_job_hh
       and prf_tick>0;
           

   -- 시간별 평균손실틱= 틱이 0보다 작은 경우 
    UPDATE hourly_trader_tot_tbl
       SET loss_avg_tick = ifnull((loss_tick/loss_tick_cnt),0)
     WHERE ymd = p_job_ymd
       AND hh = p_job_hh
       and loss_tick<0;

END;
