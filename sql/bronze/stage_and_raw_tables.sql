-- Use the project role that owns the database and integration.
USE ROLE URBANASSIST_ENGINEER;

-- Select the project warehouse for LIST and later data-loading operations.
USE WAREHOUSE URBANASSIST_WH;

-- Select the project database containing all medallion schemas.
USE DATABASE URBANASSIST_DB;

-- Create stage-related objects in the operational schema.
USE SCHEMA OPS;

CREATE FILE FORMAT IF NOT EXISTS JSON_GZIP_FF
  TYPE = JSON
  COMPRESSION = AUTO
  STRIP_OUTER_ARRAY = FALSE
  COMMENT = 'JSON Lines input; gzip is detected automatically';

-- Create a named external stage pointing to the project root in S3. The stage
-- reuses both the IAM trust object and the JSON parsing rules defined above.
CREATE STAGE IF NOT EXISTS URBANASSIST_DB.OPS.URBANASSIST_S3_STAGE_2
  URL = 's3://urbanassist-360-dev/urbanassist/'
  STORAGE_INTEGRATION = URBANASSIST_S3_INT_DEV_1
  FILE_FORMAT = JSON_GZIP_FF
  COMMENT = 'External stage rooted at the UrbanAssist project prefix';

-- drop stage URBANASSIST_S3_STAGE_1

LIST @URBANASSIST_S3_STAGE_2;


DESC STAGE URBANASSIST_S3_STAGE_2;


CREATE TABLE IF NOT EXISTS BRONZE.RAW_BOOKING_EVENTS (
  payload             VARIANT       NOT NULL,
  source_filename     VARCHAR       NOT NULL,
  source_row_number   NUMBER        NOT NULL,
  ingested_at         TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  CONSTRAINT uq_raw_booking_source UNIQUE (source_filename, source_row_number)
)
COMMENT = 'Append-only booking snapshots exactly as received from S3';


CREATE TABLE IF NOT EXISTS BRONZE.RAW_PROVIDER_EVENTS (
  payload             VARIANT       NOT NULL,
  source_filename     VARCHAR       NOT NULL,
  source_row_number   NUMBER        NOT NULL,
  ingested_at         TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  CONSTRAINT uq_raw_provider_source UNIQUE (source_filename, source_row_number)
)
COMMENT = 'Append-only provider snapshots used to build the SCD2 dimension';



CREATE TABLE IF NOT EXISTS BRONZE.RAW_CUSTOMERS (
  payload             VARIANT       NOT NULL,
  source_filename     VARCHAR       NOT NULL,
  source_row_number   NUMBER        NOT NULL,
  ingested_at         TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'One-time customer reference landing table';


CREATE TABLE IF NOT EXISTS BRONZE.RAW_SERVICES (
  payload             VARIANT       NOT NULL,
  source_filename     VARCHAR       NOT NULL,
  source_row_number   NUMBER        NOT NULL,
  ingested_at         TIMESTAMP_LTZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'One-time service reference landing table';
