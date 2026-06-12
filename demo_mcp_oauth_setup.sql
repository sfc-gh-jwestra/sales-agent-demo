-- =============================================================================
-- Snowflake MCP Server + OAuth Setup for Claude Code
-- 
-- Assumes SALES_DEMO_AGENT already exists in TARGET_DATABASE.TARGET_SCHEMA.
-- (Run demodb_sales_setup.sql first to create it.)
--
-- This script creates:
--   1. An MCP Server that exposes SALES_DEMO_AGENT + SQL execution as tools
--   2. An OAuth security integration for Claude Code (via mcp-remote)
--   3. Required grants
--
-- CONFIGURATION: Update these variables before running
-- =============================================================================

-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ CONFIGURABLE VARIABLES - Update these for your environment                  │
-- └─────────────────────────────────────────────────────────────────────────────┘

-- Account identifier (org-account format, hyphens not underscores)
-- Find yours with: SELECT CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME();
-- Then replace underscores with hyphens in the result.
SET SNOWFLAKE_ACCOUNT_LOCATOR = 'sfsenorthamerica-jwestra-aws1';  -- org-account with hyphens

SET TARGET_DATABASE = 'DEMO_DB';
SET TARGET_SCHEMA = 'SALES';
SET WAREHOUSE = 'COMPUTE_WH';
SET AGENT_ROLE = 'SYSADMIN';                    -- Role that will use the agent
SET OAUTH_REDIRECT_PORT = '3334';               -- Port for mcp-remote OAuth callback

-- Derived values (no changes needed)
SET AGENT_FQN = $TARGET_DATABASE || '.' || $TARGET_SCHEMA || '.SALES_DEMO_AGENT';
SET MCP_SERVER_FQN = $TARGET_DATABASE || '.' || $TARGET_SCHEMA || '.SALES_MCP_SERVER';
SET OAUTH_REDIRECT_URI = 'http://localhost:' || $OAUTH_REDIRECT_PORT || '/oauth/callback';

USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- STEP 1: Create the MCP Server
--
-- Exposes the SALES_DEMO_AGENT and a read-only SQL tool to Claude Code.
-- The MCP endpoint URL will be:
--   https://<SNOWFLAKE_ACCOUNT_LOCATOR>.snowflakecomputing.com/api/v2/databases/<db>/schemas/<schema>/mcp-servers/<server>
-- =============================================================================

CREATE OR REPLACE MCP SERVER IDENTIFIER($MCP_SERVER_FQN)
  FROM SPECIFICATION $$
    tools:
      - title: "Sales Demo Agent"
        name: "sales_agent"
        type: "CORTEX_AGENT_RUN"
        identifier: "DEMO_DB.SALES.SALES_DEMO_AGENT"
        description: "Sales analytics agent. Ask natural language questions about customers, products, orders, markets, revenue, discounts, and sales trends. The agent generates and executes SQL against the sales data model."

      - title: "SQL Execution"
        name: "execute_sql"
        type: "SYSTEM_EXECUTE_SQL"
        description: "Execute read-only SQL queries directly against DEMO_DB.SALES tables (CUSTOMERS, MARKETS, PRODUCTS, ORDERS, ORDER_ITEMS). Use for ad-hoc data exploration when you need precise control over the query."
  $$;

-- Verify MCP server creation
SHOW MCP SERVERS IN SCHEMA IDENTIFIER($TARGET_DATABASE || '.' || $TARGET_SCHEMA);
DESCRIBE MCP SERVER IDENTIFIER($MCP_SERVER_FQN);

-- =============================================================================
-- STEP 2: Create the OAuth Security Integration
--
-- Claude Code uses mcp-remote with --static-oauth-client-info.
-- CONFIDENTIAL client type provides client_id + client_secret.
-- Redirect URI must match mcp-remote's local callback: http://localhost:<port>/oauth/callback
-- =============================================================================

CREATE OR REPLACE SECURITY INTEGRATION CLAUDE_CODE_SALES_MCP_OAUTH
  TYPE = OAUTH
  OAUTH_CLIENT = CUSTOM
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = $OAUTH_REDIRECT_URI
  OAUTH_ISSUE_REFRESH_TOKENS = TRUE
  OAUTH_REFRESH_TOKEN_VALIDITY = 7776000
  OAUTH_USE_SECONDARY_ROLES = IMPLICIT
  ENABLED = TRUE
  OAUTH_ALLOW_NON_TLS_REDIRECT_URI = TRUE;

-- Retrieve the OAuth client ID and secret (needed for mcp-remote --static-oauth-client-info)
SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('CLAUDE_CODE_SALES_MCP_OAUTH') AS oauth_credentials;

-- =============================================================================
-- STEP 3: Grant Permissions
-- =============================================================================

-- MCP Server access
GRANT USAGE ON MCP SERVER IDENTIFIER($MCP_SERVER_FQN) TO ROLE IDENTIFIER($AGENT_ROLE);

-- Agent access
GRANT USAGE ON AGENT IDENTIFIER($AGENT_FQN) TO ROLE IDENTIFIER($AGENT_ROLE);

-- Database/schema access
GRANT USAGE ON DATABASE IDENTIFIER($TARGET_DATABASE) TO ROLE IDENTIFIER($AGENT_ROLE);
GRANT USAGE ON SCHEMA IDENTIFIER($TARGET_DATABASE || '.' || $TARGET_SCHEMA) TO ROLE IDENTIFIER($AGENT_ROLE);
GRANT SELECT ON ALL TABLES IN SCHEMA IDENTIFIER($TARGET_DATABASE || '.' || $TARGET_SCHEMA) TO ROLE IDENTIFIER($AGENT_ROLE);
GRANT SELECT ON ALL VIEWS IN SCHEMA IDENTIFIER($TARGET_DATABASE || '.' || $TARGET_SCHEMA) TO ROLE IDENTIFIER($AGENT_ROLE);

-- Warehouse access
GRANT USAGE ON WAREHOUSE IDENTIFIER($WAREHOUSE) TO ROLE IDENTIFIER($AGENT_ROLE);

-- =============================================================================
-- STEP 4: Print the MCP Server endpoint URL and .mcp.json configuration
-- =============================================================================

SELECT 'https://' || $SNOWFLAKE_ACCOUNT_LOCATOR || '.snowflakecomputing.com/api/v2/databases/' 
       || LOWER($TARGET_DATABASE) || '/schemas/' || LOWER($TARGET_SCHEMA) 
       || '/mcp-servers/' || LOWER('SALES_MCP_SERVER') AS mcp_endpoint_url;

-- =============================================================================
-- STEP 5: Configure Claude Code
-- =============================================================================
-- 
-- After running this script:
--   1. Copy OAUTH_CLIENT_ID and OAUTH_CLIENT_SECRET from the oauth_credentials output
--   2. Create .mcp.json in your project directory:
--
-- {
--   "mcpServers": {
--     "snowflake-sales-agent": {
--       "command": "npx",
--       "args": [
--         "mcp-remote",
--         "<mcp_endpoint_url from STEP 4>",
--         "3334",
--         "--static-oauth-client-metadata",
--         "{\"scope\": \"session:role:SYSADMIN\"}",
--         "--static-oauth-client-info",
--         "{\"client_id\": \"<OAUTH_CLIENT_ID>\", \"client_secret\": \"<OAUTH_CLIENT_SECRET>\"}"
--       ]
--     }
--   }
-- }
--
--   3. Create .claude/settings.local.json:
--
-- {
--   "enableAllProjectMcpServers": true,
--   "enabledMcpjsonServers": ["snowflake-sales-agent"]
-- }
--
--   4. Clear any cached auth: rm -rf ~/.mcp-auth/
--   5. Launch Claude Code from the project directory: claude
--   6. First use will open browser for OAuth consent
-- =============================================================================
