#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$(cd "${SCRIPT_DIR}/data" && pwd)"
# Push the script directory onto the directory stack
pushd "$SCRIPT_DIR" > /dev/null
snow sql --filename "${SCRIPT_DIR}/setup.sql" \
  --variable SNOWFLAKE_DATABASE="${SNOWFLAKE_MCP_DEMO_DATABASE}" \
  --variable SNOWFLAKE_WAREHOUSE="${SNOWFLAKE_MCP_DEMO_WAREHOUSE}" \
  --variable SNOWFLAKE_ROLE="${SNOWFLAKE_MCP_DEMO_ROLE}" \
  --variable DATA_DIR="${DATA_DIR}" \
  --variable SNOWFLAKE_USER="${SNOWFLAKE_USER}"

# upload the data files to the stage
snow stage copy --overwrite "${DATA_DIR}/*" "@$SNOWFLAKE_MCP_DEMO_DATABASE.data.docs"

# refresh the directory table metadata to trigger streams
snow sql --query "use role $SNOWFLAKE_MCP_DEMO_ROLE; use database $SNOWFLAKE_MCP_DEMO_DATABASE; use schema data; alter stage docs refresh;" || true

snow sql --query "use role $SNOWFLAKE_MCP_DEMO_ROLE; use database $SNOWFLAKE_MCP_DEMO_DATABASE; use schema data; execute task SYNC_DOCS;" || true
