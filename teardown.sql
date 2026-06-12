-- =============================================================================
-- Teardown: Remove all demo resources
--
-- Run this script to clean up all objects created by:
--   1. demodb_sales_setup.sql
--   2. demo_mcp_oauth_setup.sql
--
-- WARNING: This permanently deletes data. Make sure you no longer need
-- the demo environment before running.
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- STEP 1: Drop MCP Server and OAuth Integration (from demo_mcp_oauth_setup.sql)
-- =============================================================================

DROP MCP SERVER IF EXISTS DEMO_DB.SALES.SALES_MCP_SERVER;
DROP SECURITY INTEGRATION IF EXISTS CLAUDE_CODE_SALES_MCP_OAUTH;

-- =============================================================================
-- STEP 2: Drop Agent and Semantic View (from demodb_sales_setup.sql)
-- =============================================================================

DROP AGENT IF EXISTS DEMO_DB.SALES.SALES_DEMO_AGENT;
DROP SEMANTIC VIEW IF EXISTS DEMO_DB.SALES.SALES_ANALYTICS;

-- =============================================================================
-- STEP 3: Drop the Database (cascades tables and schema)
-- =============================================================================

DROP DATABASE IF EXISTS DEMO_DB;

-- =============================================================================
-- STEP 4: Drop the Warehouse
-- =============================================================================

DROP WAREHOUSE IF EXISTS DEMO_WH;

-- =============================================================================
-- DONE
-- =============================================================================
--
-- Removed:
--   MCP Server:            DEMO_DB.SALES.SALES_MCP_SERVER
--   Security Integration:  CLAUDE_CODE_SALES_MCP_OAUTH
--   Agent:                 DEMO_DB.SALES.SALES_DEMO_AGENT
--   Semantic View:         DEMO_DB.SALES.SALES_ANALYTICS
--   Database:              DEMO_DB (includes schema, tables, and all data)
--   Warehouse:             DEMO_WH
--
-- To also clean up local OAuth tokens:
--   rm -rf ~/.mcp-auth/
-- =============================================================================
