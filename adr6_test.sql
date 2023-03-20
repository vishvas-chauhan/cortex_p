MERGE `gavitalfield.DS_CDC.adr6_test` AS T
USING (
  WITH
    S0 AS (
      SELECT * FROM `gavitalfield.DS_RAW.adr6_test`
      WHERE recordstamp >= (
        SELECT IFNULL(MAX(recordstamp), TIMESTAMP('1940-12-25 05:30:00+00'))
        FROM `gavitalfield.DS_CDC.adr6_test`)
    ),
    -- To handle occasional dups from SLT connector
    S1 AS (
      SELECT * EXCEPT(row_num)
      FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY CLIENT, PERSNUMBER, DATE_FROM, CONSNUMBER, ADDRNUMBER, recordstamp ORDER BY recordstamp) AS row_num
        FROM S0
      )
      WHERE row_num = 1
    ),
    T1 AS (
      SELECT CLIENT, PERSNUMBER, DATE_FROM, CONSNUMBER, ADDRNUMBER, MAX(recordstamp) AS recordstamp
      FROM `gavitalfield.DS_RAW.adr6_test`
      WHERE recordstamp >= (
        SELECT IFNULL(MAX(recordstamp), TIMESTAMP('1940-12-25 05:30:00+00'))
        FROM `gavitalfield.DS_CDC.adr6_test`)
      GROUP BY CLIENT, PERSNUMBER, DATE_FROM, CONSNUMBER, ADDRNUMBER
    )
  SELECT S1.*
  FROM S1
  INNER JOIN T1
    ON S1.`CLIENT` = T1.`CLIENT` AND S1.`PERSNUMBER` = T1.`PERSNUMBER` AND S1.`DATE_FROM` = T1.`DATE_FROM` AND S1.`CONSNUMBER` = T1.`CONSNUMBER` AND S1.`ADDRNUMBER` = T1.`ADDRNUMBER`
      AND S1.recordstamp = T1.recordstamp
  ) AS S
ON S.`CLIENT` = T.`CLIENT` AND S.`PERSNUMBER` = T.`PERSNUMBER` AND S.`DATE_FROM` = T.`DATE_FROM` AND S.`CONSNUMBER` = T.`CONSNUMBER` AND S.`ADDRNUMBER` = T.`ADDRNUMBER`
-- ## CORTEX-CUSTOMER You can use "`is_deleted` = true" condition along with "operation_flag = 'D'",
-- if that is applicable to your CDC set up.
WHEN NOT MATCHED AND IFNULL(S.operation_flag, 'I') != 'D' THEN
  INSERT (`client`, `addrnumber`, `persnumber`, `date_from`, `consnumber`, `flgdefault`, `flg_nouse`, `home_flag`, `smtp_addr`, `smtp_srch`, `dft_receiv`, `r3_user`, `encode`, `tnef`, `valid_from`, `valid_to`, `recordstamp`)
  VALUES (`client`, `addrnumber`, `persnumber`, `date_from`, `consnumber`, `flgdefault`, `flg_nouse`, `home_flag`, `smtp_addr`, `smtp_srch`, `dft_receiv`, `r3_user`, `encode`, `tnef`, `valid_from`, `valid_to`, `recordstamp`)
WHEN MATCHED AND S.operation_flag = 'D' THEN
  DELETE
WHEN MATCHED AND S.operation_flag = 'U' THEN
  UPDATE SET T.`client` = S.`client`, T.`addrnumber` = S.`addrnumber`, T.`persnumber` = S.`persnumber`, T.`date_from` = S.`date_from`, T.`consnumber` = S.`consnumber`, T.`flgdefault` = S.`flgdefault`, T.`flg_nouse` = S.`flg_nouse`, T.`home_flag` = S.`home_flag`, T.`smtp_addr` = S.`smtp_addr`, T.`smtp_srch` = S.`smtp_srch`, T.`dft_receiv` = S.`dft_receiv`, T.`r3_user` = S.`r3_user`, T.`encode` = S.`encode`, T.`tnef` = S.`tnef`, T.`valid_from` = S.`valid_from`, T.`valid_to` = S.`valid_to`, T.`recordstamp` = S.`recordstamp`;
