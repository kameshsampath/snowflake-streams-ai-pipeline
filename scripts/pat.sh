#!/usr/bin/env bash

set -euo pipefail

## Setup Service User for Cortex Agent
snow sql --stdin <<EOF
    use role accountadmin;
    CREATE USER IF NOT EXISTS $SA_USER
        TYPE = SERVICE
        COMMENT = 'Service User For Cortex Agents MCP Demo';
    GRANT ROLE $SNOWFLAKE_MCP_DEMO_ROLE TO USER $SA_USER;
EOF

# # Get GitHub Actions IP ranges only IPV4
# Uncomment the following lines if you want to fetch GitHub Actions IP ranges dynamically
# GH_CIDRS=$(curl -s https://api.github.com/meta | jq -r '.actions | map(select(contains(":") | not)) | map("'\''" + . + "'\''") | join(",")')

# Get local IP and add /32 suffix
LOCAL_IP="$(dig +short myip.opendns.com @resolver1.opendns.com)/32"

# Combine GitHub CIDRs and local IP
CIDR_VALUE_LIST="'${LOCAL_IP}'"

# Create or alter the network rule and policy
snow sql --query "use role accountadmin;alter user $SA_USER unset network_policy;" || true
snow sql --stdin <<EOF
use role $SNOWFLAKE_MCP_DEMO_ROLE;
use database $SNOWFLAKE_MCP_DEMO_DATABASE;
create schema if not exists networks;
create schema if not exists policies;

use role accountadmin;

-- unset and drop the network policy on the user
alter user "${SA_USER}" unset network_policy;
drop network policy if exists LOCAL_PAT_NETWORK_POLICY;
use role $SNOWFLAKE_MCP_DEMO_ROLE;
-- create or replace network rule to allow local machine IPv4 addresses
create or replace network rule $SNOWFLAKE_MCP_DEMO_DATABASE.networks.pat_local_access_rule
  mode = ingress
  type = ipv4
  value_list = ($CIDR_VALUE_LIST)
  comment = 'Allow only local machine IPv4 addresses';
-- attach the network rule to the network policy
use role accountadmin;
create network policy LOCAL_PAT_NETWORK_POLICY
allowed_network_rule_list = ('"$SNOWFLAKE_MCP_DEMO_DATABASE".networks.pat_local_access_rule')
comment = 'Network policy to allow all IPv4 addresses.';
alter user "${SA_USER}" set network_policy='LOCAL_PAT_NETWORK_POLICY';
EOF

# Create or alter the authentication policy that will be set to the service user
snow sql --query "use role accountadmin;alter user $SA_USER unset AUTHENTICATION POLICY;" || true
snow sql --stdin <<EOF
use role $SNOWFLAKE_MCP_DEMO_ROLE;
create or replace authentication policy $SNOWFLAKE_MCP_DEMO_DATABASE.policies."${USER}_mcp_auth_policy"
  authentication_methods = ('PROGRAMMATIC_ACCESS_TOKEN')
  pat_policy = (
    default_expiry_in_days=15,
    max_expiry_in_days=30,
    network_policy_evaluation = ENFORCED_REQUIRED
  );
 alter user $SA_USER set AUTHENTICATION POLICY $SNOWFLAKE_MCP_DEMO_DATABASE.policies."${USER}_mcp_auth_policy";
EOF

# Create PAT for the service user
# Check if PAT already exists
EXISTING_PAT=$( snow sql -q "show pats for user $SA_USER" \
  --format=json \
  | jq -r '.[] | select(.name|ascii_downcase == "mcp_demo") | .name')

if [ -z "$EXISTING_PAT" ]; then
  # Create PAT if it doesn't exist
  echo "Creating new PAT for service user $SA_USER..."
  SNOWFLAKE_SA_PASSWORD=$(snow sql \
    --query "ALTER USER IF EXISTS $SA_USER ADD PAT mcp_demo ROLE_RESTRICTION = $SNOWFLAKE_MCP_DEMO_ROLE" \
    --format=json | jq -r '.[] | .token_secret')
else
  echo "PAT for service user $SA_USER already exists. Rotating PAT..."
  # Rotate PAT
  SNOWFLAKE_SA_PASSWORD=$(snow sql \
    --query "ALTER USER IF EXISTS $SA_USER ROTATE PAT mcp_demo" \
    --format=json | jq -r '.[] | .token_secret')
fi;

echo "Service User PAT created successfully."
sed -i "s/^SNOWFLAKE_PASSWORD=.*/SNOWFLAKE_PASSWORD=$SNOWFLAKE_SA_PASSWORD/" .env
