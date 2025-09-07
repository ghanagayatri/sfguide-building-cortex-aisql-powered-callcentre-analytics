-- Create database and schemas
USE ROLE ACCOUNTADMIN;
CREATE ROLE IF NOT EXISTS DE_DEMO_ROLE;
CREATE DATABASE IF NOT EXISTS call_centre_analytics_db;
-- Create warehouse
CREATE WAREHOUSE IF NOT EXISTS cca_xs_wh 
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

USE DATABASE call_centre_analytics_db;
USE SCHEMA PUBLIC;

CREATE OR REPLACE API INTEGRATION GITHUB_INTEGRATION_CALL_CENTER_DEMO
    api_provider = git_https_api
    api_allowed_prefixes = ('https://github.com/ghanagayatri/')
    enabled = true
    comment='Git integration with Snowflake-Labs Github Repository.';

-- Create the integration with the Github demo repository
CREATE GIT REPOSITORY GITHUB_REPO_CALL_CENTER_DEMO
	ORIGIN = 'https://github.com/ghanagayatri/sfguide-building-cortex-aisql-powered-callcentre-analytics.git' 
	API_INTEGRATION = 'GITHUB_INTEGRATION_CALL_CENTER_DEMO' 
	COMMENT = 'Github Repository from Snowflake-Labs with a demo for Call Center Analytics.';


GRANT READ ON GIT REPOSITORY call_centre_analytics_db.public.GITHUB_REPO_CALL_CENTER_DEMO TO ROLE DE_DEMO_ROLE;


-- GRANT OWNERSHIP ON THE DB TO THE CUSTOM ROLE
GRANT OWNERSHIP ON DATABASE call_centre_analytics_db TO ROLE DE_DEMO_ROLE COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL SCHEMAS IN DATABASE call_centre_analytics_db TO ROLE DE_DEMO_ROLE COPY CURRENT GRANTS;

GRANT USAGE ON WAREHOUSE cca_xs_wh TO ROLE DE_DEMO_ROLE;

GRANT EXECUTE TASK ON ACCOUNT TO ROLE DE_DEMO_ROLE;

-- Update the username 
GRANT ROLE DE_DEMO_ROLE TO USER GGHANAKOTA ; 

USE ROLE DE_DEMO_ROLE;
USE DATABASE call_centre_analytics_db;
USE WAREHOUSE cca_xs_wh;
USE SCHEMA PUBLIC;

CREATE STAGE IF NOT EXISTS UDF
ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
DIRECTORY = (ENABLE = TRUE)
COMMENT = ' used to create UDFs';
CREATE STAGE IF NOT EXISTS AUDIO_FILES
ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
DIRECTORY = (ENABLE = TRUE)
COMMENT = ' stage for Cortex Analyst semantic model files';;;

CREATE STAGE IF NOT EXISTS SEMANTIC_MODEL_STAGE
ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
DIRECTORY = (ENABLE = TRUE)
COMMENT = ' stores the semantic yaml file for cortex analyst';


CREATE STAGE IF NOT EXISTS AUDIO_FILES
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = ( ENABLE = true )
    COMMENT = 'Used to store recordings';

CREATE STAGE IF NOT EXISTS UDF
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Used to create UDFs';


-- Copy audio files into the stage
COPY FILES
  INTO @AUDIO_FILES
  FROM @CALL_CENTRE_ANALYTICS_DB.PUBLIC.GITHUB_REPO_CALL_CENTER_DEMO/branches/main/audio_files/
  PATTERN='.*[.]mp3';
ALTER STAGE AUDIO_FILES REFRESH;


COPY FILES
  INTO @SEMANTIC_MODEL_STAGE
  FROM @CALL_CENTRE_ANALYTICS_DB.PUBLIC.GITHUB_REPO_CALL_CENTER_DEMO/branches/main/call_center_analytics_model.yaml;
  
ALTER STAGE SEMANTIC_MODEL_STAGE REFRESH;
