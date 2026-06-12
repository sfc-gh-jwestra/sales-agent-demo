# Claude Code → Snowflake Sales Agent via MCP + OAuth

The main purpose is to show end-to-end agentic workflow from Claude Code to Snowflake, secured by OAuth.

Connect **Claude Code** to a **Snowflake Cortex Agent** (`SALES_DEMO_AGENT`) exposed through an MCP Server with OAuth authentication.

The demo is a small sales app showing customers, products, orders, order items. Use the streamlit dashboard to
view data. Use Claude Code to ask questions about data through a Cortex Agent (via OAuth/MCP).

## Future Enhancements:
Sample will expand to show
1. RBAC and Row Access Policy to govern access to certain customers data
2. User context passed to track agent expenses by user


## Architecture

```
Claude Code  ──stdio──>  mcp-remote  ──HTTP + OAuth──>  Snowflake MCP Server
                          (PKCE flow)                     │
                                                          ├─ sales_agent tool ──> SALES_DEMO_AGENT (Cortex Agent)
                                                          │                         └─ SALES_ANALYTICS semantic view
                                                          │                             └─ CUSTOMERS, PRODUCTS, ORDERS,
                                                          │                                ORDER_ITEMS, MARKETS tables
                                                          └─ execute_sql tool ──> Read-only SQL on DEMO_DB.SALES
```

## Files

| File | Purpose |
|------|---------|
| `demodb_sales_setup.sql` | Creates database, tables, data, semantic view, and Cortex Agent |
| `demo_mcp_oauth_setup.sql` | Creates MCP Server, OAuth integration, and grants |
| `mcp_config.json` | Template for Claude Code `.mcp.json` (fill in placeholders) |
| `.mcp.json` | Live Claude Code MCP configuration (with real credentials) |
| `.claude/settings.local.json` | Claude Code local settings to enable the MCP server |

## Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `SNOWFLAKE_ACCOUNT_LOCATOR` | Org-account with hyphens (not underscores) | `sfsenorthamerica-jwestra-aws1` |
| `TARGET_DATABASE` | Database containing the sales data | `DEMO_DB` |
| `TARGET_SCHEMA` | Schema containing the sales tables | `SALES` |
| `WAREHOUSE` | Warehouse for query execution | `COMPUTE_WH` |
| `AGENT_ROLE` | Role that will access the agent/MCP server | `SYSADMIN` |
| `OAUTH_REDIRECT_PORT` | Local port for mcp-remote OAuth callback | `3334` |

Find your account locator:
```sql
SELECT CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME();
-- Then replace any underscores with hyphens in the result
```

## Prerequisites

- Snowflake account with ACCOUNTADMIN access
- Claude Code installed
- Node.js 18+ (for `npx mcp-remote`)

## Setup (from scratch)

### Step 1: Create the Database and Agent

```bash
snowsql -a <your-account> -u <your-user> -f demodb_sales_setup.sql
```

### Step 2: Create the MCP Server and OAuth Integration

```bash
snowsql -a <your-account> -u <your-user> -f demo_mcp_oauth_setup.sql
```

### Step 3: Get OAuth Credentials

From the script output, copy `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET`.

### Step 4: Create `.mcp.json`

Copy `mcp_config.json` to `.mcp.json` and replace all `{{placeholders}}`:

```json
{
  "mcpServers": {
    "snowflake-sales-agent": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://<ACCOUNT_LOCATOR>.snowflakecomputing.com/api/v2/databases/demo_db/schemas/sales/mcp-servers/sales_mcp_server",
        "3334",
        "--static-oauth-client-metadata",
        "{\"scope\": \"session:role:SYSADMIN\"}",
        "--static-oauth-client-info",
        "{\"client_id\": \"<CLIENT_ID>\", \"client_secret\": \"<CLIENT_SECRET>\"}"
      ]
    }
  }
}
```

### Step 5: Create `.claude/settings.local.json`

```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["snowflake-sales-agent"]
}
```

### Step 6: Clear cache and launch

```bash
rm -rf ~/.mcp-auth/
claude
```

First use opens a browser for OAuth consent. After authorizing, the token is cached.

## Key Technical Details

### MCP Server Endpoint URL Format

```
https://<org>-<account>.snowflakecomputing.com/api/v2/databases/<db>/schemas/<schema>/mcp-servers/<server_name>
```

- Use **hyphens** (not underscores) in org-account hostname
- Database/schema/server names are **case-insensitive** in the URL path

### OAuth Integration Requirements

| Setting | Value | Why |
|---------|-------|-----|
| `OAUTH_CLIENT_TYPE` | `CONFIDENTIAL` | mcp-remote passes client_secret |
| `OAUTH_REDIRECT_URI` | `http://localhost:3334/oauth/callback` | mcp-remote's local callback |
| `OAUTH_USE_SECONDARY_ROLES` | `IMPLICIT` | Allows role switching |
| `OAUTH_ALLOW_NON_TLS_REDIRECT_URI` | `TRUE` | Localhost is HTTP |

### mcp-remote Flags

| Flag | Purpose |
|------|---------|
| `3334` (positional) | Port for local OAuth callback server |
| `--static-oauth-client-metadata '{"scope": "..."}'` | Requests specific role scope (avoids "role ALL blocked" error) |
| `--static-oauth-client-info '{"client_id": "...", "client_secret": "..."}'` | Pre-registered client (bypasses DCR) |

### MCP Server Spec (YAML)

Valid tool types:
- `CORTEX_AGENT_RUN` — Cortex Agent (requires `identifier`)
- `CORTEX_ANALYST_MESSAGE` — Semantic view (requires `identifier`)
- `CORTEX_SEARCH_SERVICE_QUERY` — Cortex Search (requires `identifier`)
- `SYSTEM_EXECUTE_SQL` — SQL execution
- `GENERIC` — UDF/procedure (requires `identifier` + `config`)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "does not support dynamic client registration" | Use `--static-oauth-client-info` (not `--client-id`) |
| "role ALL has been explicitly blocked" | Add `--static-oauth-client-metadata '{"scope": "session:role:SYSADMIN"}'` |
| 404 on endpoint | Use org-account URL format with `/api/v2/databases/.../mcp-servers/...` path |
| Port already in use | Change port in `.mcp.json` AND `OAUTH_REDIRECT_URI` in security integration |
| Stale auth | Run `rm -rf ~/.mcp-auth/` and restart Claude Code |
| MCP not visible in Claude | Ensure `.claude/settings.local.json` has `enableAllProjectMcpServers: true` |
