USE ROLE URBANASSIST_ENGINEER;

USE WAREHOUSE URBANASSIST_WH;

USE DATABASE URBANASSIST_DB;

USE SCHEMA OPS;

-- ---------- Ingestion health ----------
-- Inspect booking/provider Snowpipe queue state and its most recent ingestion outcome.

SELECT SYSTEM$PIPE_STATUS('URBANASSIST_DB.OPS.BOOKING_EVENTS_PIPE') AS booking_pipe_status;

SELECT SYSTEM$PIPE_STATUS('URBANASSIST_DB.OPS.PROVIDER_EVENTS_PIPE') AS provider_pipe_status;


-- TRUE means provider rows are waiting to be consumed by the SCD2 procedure.
SELECT SYSTEM$STREAM_HAS_DATA('URBANASSIST_DB.OPS.PROVIDER_EVENTS_STREAM') AS provider_change_ready;

-- TRUE means new booking snapshots are waiting for review enrichment evaluation.
SELECT SYSTEM$STREAM_HAS_DATA('URBANASSIST_DB.OPS.BOOKING_REVIEW_STREAM') AS review_change_ready;

SHOW TASKS IN SCHEMA URBANASSIST_DB.OPS;


-- Review recent booking COPY attempts, loaded files, errors, and row counts.
SELECT *
FROM TABLE(
  INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'URBANASSIST_DB.BRONZE.RAW_BOOKING_EVENTS',
    START_TIME => DATEADD('DAY', -1, CURRENT_TIMESTAMP())
  )
)
ORDER BY LAST_LOAD_TIME DESC;



SELECT 'BRONZE_PHYSICAL_BOOKING_ROWS' AS measure, COUNT(*) AS value
FROM BRONZE.RAW_BOOKING_EVENTS
UNION ALL
SELECT 'BRONZE_DISTINCT_BOOKINGS', COUNT(DISTINCT payload:booking_id::VARCHAR)
FROM BRONZE.RAW_BOOKING_EVENTS
UNION ALL
SELECT 'SILVER_LATEST_BOOKINGS', COUNT(*)
FROM SILVER.DT_BOOKINGS_CLEAN
UNION ALL
SELECT 'GOLD_FACT_BOOKINGS', COUNT(*)
FROM GOLD.FACT_BOOKING
UNION ALL
SELECT 'AI_ENRICHED_REVIEWS', COUNT(*)
FROM GOLD.FACT_REVIEW_INSIGHT;



-- Refresh latest booking state immediately instead of waiting for target lag.
ALTER DYNAMIC TABLE SILVER.DT_BOOKINGS_CLEAN REFRESH;

-- Refresh clean provider events for transparent inspection of the live rows.
ALTER DYNAMIC TABLE SILVER.DT_PROVIDER_CHANGES_CLEAN REFRESH;

-- Rebuild the booking fact after Silver and SCD2 processing are current.
ALTER DYNAMIC TABLE GOLD.FACT_BOOKING REFRESH;

-- Rebuild the dependent daily KPI aggregate from current Gold results.
ALTER DYNAMIC TABLE GOLD.DT_DAILY_SERVICE_KPI REFRESH;



