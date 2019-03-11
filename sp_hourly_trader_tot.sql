DROP PROCEDURE IF EXISTS sp_hourly_trader_tot;
CREATE PROCEDURE `sp_hourly_trader_tot`(in p_job_ymd date, in p_job_hh char(2),p_last_mat_no int)
BEGIN
  #declare variable
  DECLARE v_last_job_time,v_last_data_time timestamp;
  DECLARE v_last_mat_no, v_max_mat_no int;
  DECLARE v_job_done_yn varchar(1);
-- 0 ���� ���� ������ û��� ���þ��� �͵�.

# ������ �����ϴ� ���� delete���� �ʰ� �׳� updateģ��.
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
          count(*),                                                    -- �Ÿ�Ƚ��
          sum(stl_qty), -- �Ÿż���
          sum(hold_time), -- �����ð�
          sum(prf_yn),                                                -- �̱� Ƚ��
          sum(CASE prf_yn WHEN 0 THEN 1 ELSE 0 END), -- �� Ƚ�� 
          sum(CASE WHEN ent_stl_tic > 0 THEN ent_stl_tic ELSE 0 END),   -- ���� ƽ 
          (sum(CASE WHEN ent_stl_tic < 0 THEN ent_stl_tic ELSE 0 END)), -- �ս�ƽ 
          sum(prf_rate),                                                -- ���ͷ�
          sum(pls_amt),                                                 -- ���ͱ�
          ifnull((sum(prf_yn) * 100) / count(*),0),  -- �·�
          0, -- �ð��� ��� ����ƽ 
          0,   -- �ð��� ��ռս�ƽ
          max(CASE WHEN prf_rate > 0 THEN prf_rate ELSE 0 END), -- 1ȸ �ִ���ͷ�
          min(CASE WHEN prf_rate < 0 THEN prf_rate ELSE 0 END), -- 1ȸ �ִ�սǷ�
          avg(prf_rate), -- ��� ���ͷ� 
          0, -- ���� �Ÿ�Ƚ��//û���� �ƴ� ��ü ���� �Ÿ�Ƚ�� 
          0, -- 1ȸ �ֹ��ִ���� //û���� �ƴ� ��ü �ִ���� 
          count(*), -- ��ոŸ� Ƚ���� �ϰ����̺������ count�� sum�� �ϰ� �Ϸ� �̻� �����͸� ������ avg�� ������.
          sum(stl_qty)/count(*), -- ��ոŸż���
          avg(hold_time), -- ��պ����ð� 
          min(case when ent_stl_tic > 0 then ent_stl_tic else 0 end), -- �ִ� �ս�ƽ
          max(case when ent_stl_tic < 0 then ent_stl_tic else 0 end), -- �ִ� ����ƽ 
          sum(CASE WHEN ent_stl_tic > 0 THEN 1 ELSE 0 END), -- ����ƽ �ŸŰǼ�
          sum(CASE WHEN ent_stl_tic < 0 THEN 1 ELSE 0 END)-- �ս�ƽ �ŸŰǼ�
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
 
 -- �ð��� ��� ����ƽ= ƽ�� 0���� ū ��� 
    UPDATE hourly_trader_tot_tbl
       SET prf_avg_tick = ifnull((prf_tick/prt_tick_cnt),0)
     WHERE ymd = p_job_ymd
       AND hh = p_job_hh
       and prf_tick>0;
           

   -- �ð��� ��ռս�ƽ= ƽ�� 0���� ���� ��� 
    UPDATE hourly_trader_tot_tbl
       SET loss_avg_tick = ifnull((loss_tick/loss_tick_cnt),0)
     WHERE ymd = p_job_ymd
       AND hh = p_job_hh
       and loss_tick<0;

END;
