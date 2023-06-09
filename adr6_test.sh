#!/bin/bash
set -e
echo "Install required package 📦📦📦"
pip install -r requirements.txt
# bq cp gavitalfield:DS_CDC.adr6 gavitalfield:DS_CDC.adr6_test
bq query --use_legacy_sql=false '
CREATE or REPLACE TABLE `gavitalfield.DS_CDC.adr6_test`
OPTIONS(
  expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 365 DAY),
  description="Empty table with the same schema as CDC adr6"
) AS SELECT * FROM `gavitalfield.DS_CDC.adr6` WHERE 1=0'

echo "CDC table created for adr6_test with same schema ✅"

gsutil cp gs://gavitalfield-raw-sap-data-demo/ecc/adr6.parquet .

python adr6_edit.py --OF D

gsutil cp adr6_test.parquet gs://gavitalfield-raw-sap-data-demo/ecc/
echo "File has been uploaded to GCS for adr6_test  ✅"

bq query --use_legacy_sql=false '
CREATE or REPLACE TABLE `gavitalfield.DS_RAW.adr6_test`
OPTIONS(
  expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 365 DAY),
  description="Empty table with the same schema as CDC adr6"
) AS SELECT * FROM `gavitalfield.DS_RAW.adr6` WHERE 1=0'

echo "RAW table has been created for adr6_test with same schema ✅"

bq load --replace --source_format=PARQUET gavitalfield:DS_RAW.adr6_test gs://gavitalfield-raw-sap-data-demo/ecc/adr6_test.parquet

echo "New RAW data LOADED for table adr6_test ✅"


bq query \
  --use_legacy_sql=false \
  "$(cat adr6_test.sql)"

echo "⤵️ See the CDC in new ard6_test 🏆"


echo -e "\n 🧹🧹🧹 After work cleaning 🧹🧹🧹"
rm adr6_test.parquet adr6.parquet



