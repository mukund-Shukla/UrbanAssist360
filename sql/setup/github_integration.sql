-- Use ACCOUNTADMIN because creating an API integration is normally controlled
-- by an account administrator. A delegated role can be used instead when it
-- has the CREATE INTEGRATION account privilege.
USE ROLE ACCOUNTADMIN;

-- Create an HTTPS Git API integration restricted to this GitHub repository.
-- SNOWFLAKE_GITHUB_APP starts an interactive OAuth authorization when the
-- developer connects the repository in a Snowflake Workspace; no PAT is stored.
CREATE OR REPLACE API INTEGRATION URBANASSIST_GITHUB_API_INT
  API_PROVIDER = GIT_HTTPS_API
  API_ALLOWED_PREFIXES = (
    'https://github.com/mukund-Shukla/UrbanAssist360.git'
  )
  API_USER_AUTHENTICATION = (
    TYPE = SNOWFLAKE_GITHUB_APP
  )
  ENABLED = TRUE
  COMMENT = 'OAuth connection from Snowflake Workspaces to the UrbanAssist GitHub repository';

GRANT USAGE
  ON INTEGRATION URBANASSIST_GITHUB_API_INT
  TO ROLE URBANASSIST_ENGINEER;
