#!/bin/bash

# Load the parameters from the TOML file
eval $(awk -F ' = ' '/url|user|password/ {gsub(/"/, "", $2); print "REDSHIFT_" toupper($1) "=" $2}' parameters.toml)

# Extract the Redshift endpoint, port, and database name from the URL
REDSHIFT_ENDPOINT=$(echo $REDSHIFT_URL | sed -E 's/jdbc:redshift:\/\/([^:]+):([0-9]+)\/.*/\1/')
REDSHIFT_PORT=$(echo $REDSHIFT_URL | sed -E 's/jdbc:redshift:\/\/[^:]+:([0-9]+)\/.*/\1/')
REDSHIFT_DB=$(echo $REDSHIFT_URL | sed -E 's/jdbc:redshift:\/\/[^\/]+\/(.+)/\1/')

# Print extracted variables for verification
echo "URL: $REDSHIFT_URL"
echo "USER: $REDSHIFT_USER"
echo "PASSWORD: $REDSHIFT_PASSWORD"
echo "ENDPOINT: $REDSHIFT_ENDPOINT"
echo "PORT: $REDSHIFT_PORT"
echo "DATABASE: $REDSHIFT_DB"

# Extract the schemas from the parameters.toml file
schemas=$(awk '/schemas = / {flag=1; next} /"""/ {flag=0} flag {print}' parameters.toml | tr -d '\n' | sed 's/\\//g')

# Function to convert field types
convert_type() {
    case "$1" in
        "string") echo "VARCHAR(255)" ;;
        "int32") echo "INT" ;;
        "float") echo "FLOAT" ;;
        *) echo "VARCHAR(255)" ;;  # default to VARCHAR for unknown types
    esac
}

# Create SQL statements based on the schema definitions
sql_statements=$(echo "$schemas" | jq -r '
    to_entries | .[] |
    "CREATE TABLE IF NOT EXISTS " + .key + " (" +
    (
        .value.fields | map(
            .field + " " +
            (if .type == "string" then "VARCHAR(255)"
            elif .type == "int32" then "INT"
            elif .type == "float" then "FLOAT"
            else "VARCHAR(255)" end) +
            (if .optional == false then " NOT NULL" else "" end)
        ) | join(", ")
    ) + ");"
')

# Execute the SQL statements in Redshift
IFS=$'\n'
for sql in $sql_statements; do
    echo "Executing: $sql"
    PGPASSWORD=$REDSHIFT_PASSWORD psql -h $REDSHIFT_ENDPOINT -p $REDSHIFT_PORT -d $REDSHIFT_DB -U $REDSHIFT_USER -c "$sql"
done
