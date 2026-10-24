USE ROLE URBANASSIST_ENGINEER;

-- Resume the project warehouse if needed for the explicit COPY statements.
USE WAREHOUSE URBANASSIST_WH;

-- Select the project database that contains Bronze and OPS.
USE DATABASE URBANASSIST_DB;

-- Use OPS so stage and pipe names can remain unqualified.
USE SCHEMA OPS;

-- Load the customer reference file once. ABORT_STATEMENT prevents a partially
-- accepted customer master when any row in the file cannot be loaded.
COPY INTO BRONZE.RAW_CUSTOMERS
  (payload, source_filename, source_row_number)
FROM (
  SELECT $1, METADATA$FILENAME, METADATA$FILE_ROW_NUMBER
  FROM @URBANASSIST_S3_STAGE_2/reference/customers/
)
PATTERN = '.*customers[.]json[.]gz'
ON_ERROR = 'ABORT_STATEMENT';

-- Load the service catalogue with the same all-or-nothing error policy.
COPY INTO BRONZE.RAW_SERVICES
  (payload, source_filename, source_row_number)
FROM (
  SELECT $1, METADATA$FILENAME, METADATA$FILE_ROW_NUMBER
  FROM @URBANASSIST_S3_STAGE_2/reference/services/
)
PATTERN = '.*services[.]json[.]gz'
ON_ERROR = 'ABORT_STATEMENT';