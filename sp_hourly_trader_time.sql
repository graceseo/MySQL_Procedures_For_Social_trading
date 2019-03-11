DROP PROCEDURE IF EXISTS sp_hourly_trader_time;
CREATE PROCEDURE sp_hourly_trader_time(in p_kor_date_time timestamp, in p_job_ymd date )
BEGIN
  #declare variable
  DECLARE v_last_mat_no, v_max_mat_no int;
  DECLARE v_range_no,v_kor_time tinyint;
  DECLARE v_range_name varchar(6);
  -- �ְŷ� �ð��� �ѱ� �ð� ����.

  # �޾ƿ� ������¥�ͽð��� ������ ���� �ѱ� �ð��� ã�Ƽ� �ְŷ� �ð��� ã�´�.
    select kor_time into v_kor_time from stock_sts_static_db.bsns_date_mat_tbl where bsns_date=p_kor_date_time;
  
  # ������ �������� �ð��� ������ �ŷ��ð� ���̺��� ��ȣ�� �̸��� �����´�. �ѽð����� ���� ������ ������ �� row�� ���´�. ������ �ð� ���� 1�ð��� ���� ��.
    select range_no,range_name into v_range_no,v_range_name
    from stock_sts_static_db.time_range_detail_tbl where range_time=v_kor_time; -- �������̺��� �ǵ��� static���� �����´�.

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
         FROM cns_tbl  -- �ְŷ��ð��� ��ü ü�����̺��� ������.
        WHERE   ymd = p_job_ymd
              AND cns_time=v_kor_time --  �ش� �������� �ѱ� �ְŷ� �ð�
       GROUP BY ymd, trader_no
          ON DUPLICATE KEY UPDATE trade_cnt = trade_cnt +values(trade_cnt);

END;