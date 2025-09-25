#!/bin/bash
set -e

# Default command to start SonarQube
DEFAULT_CMD=('/opt/java/openjdk/bin/java' '-jar' '/opt/sonarqube/lib/sonarqube.jar' '-Dsonar.log.console=true')

# Start SonarQube in background
echo "Starting SonarQube in background..."
"${DEFAULT_CMD[@]}" &
SQ_PID=$!

# Wait for SonarQube to be ready
echo "Waiting for SonarQube to start..."
until curl -f -s http://localhost:9000/api/system/status | grep -q '"status":"UP"'; do
  if ! kill -0 $SQ_PID 2>/dev/null; then
    echo "SonarQube failed to start"
    exit 1
  fi
  sleep 10
done

echo "SonarQube is up!"

# Change admin password if default
NEW_PASSWORD="${SONARQUBE_ADMIN_PASSWORD:-MySecurePoCPass123!}"
if curl -f -s -u admin:admin http://localhost:9000/api/system/status > /dev/null 2>&1; then
  echo "Default credentials active, changing password to ${NEW_PASSWORD}..."
  curl -u admin:admin -X POST "http://localhost:9000/api/users/change_password" \
    -d "login=admin" \
    -d "previousPassword=admin" \
    -d "password=${NEW_PASSWORD}"
  echo "Password changed successfully."
else
  echo "Default credentials already updated, skipping."
fi

ADMIN_CREDENTIALS="admin:${NEW_PASSWORD}"

# Automate project creation
PROJECT_KEY="demo-ecommerce"
PROJECT_NAME="Demo E-commerce"
TOKEN_NAME="gradle-token"
TOKEN_FILE="/imports/sonarqube/sonar-token.txt"


# Check if project exists (GET /api/projects/search)
echo "Checking if project ${PROJECT_KEY} exists..."
SEARCH_RESPONSE=$(curl -s -u "${ADMIN_CREDENTIALS}" "http://localhost:9000/api/projects/search?projects=${PROJECT_KEY}")
if echo "$SEARCH_RESPONSE" | grep -q '"key":"'${PROJECT_KEY}'"'; then
  echo "Project ${PROJECT_KEY} already exists, skipping creation."
else
  echo "Creating project ${PROJECT_KEY}..."
  CREATE_RESPONSE=$(curl -s -u "${ADMIN_CREDENTIALS}" -X POST "http://localhost:9000/api/projects/create" \
    -d "project=${PROJECT_KEY}" \
    -d "name=${PROJECT_NAME}")
  if echo "$CREATE_RESPONSE" | grep -q '"key":"'${PROJECT_KEY}'"'; then
    echo "Project ${PROJECT_KEY} created successfully."
  else
    echo "Failed to create project ${PROJECT_KEY}. Response: $CREATE_RESPONSE"
  fi
fi

# Generate token if not exists (POST /api/user_tokens/generate)
echo "Checking if token ${TOKEN_NAME} exists..."
TOKEN_SEARCH=$(curl -s -u "${ADMIN_CREDENTIALS}" "http://localhost:9000/api/user_tokens/search?name=${TOKEN_NAME}")
if echo "$TOKEN_SEARCH" | grep -q '"isValid":true'; then
  echo "Token ${TOKEN_NAME} already exists, extracting..."
  TOKEN=$(echo "$TOKEN_SEARCH" | grep -o '"token":"[^"]*' | cut -d'"' -f4 | head -1)
else
  echo "Generating new token ${TOKEN_NAME}..."
  TOKEN_RESPONSE=$(curl -s -u "${ADMIN_CREDENTIALS}" -X POST "http://localhost:9000/api/user_tokens/generate?name=${TOKEN_NAME}")
  TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
fi

if [ -n "$TOKEN" ]; then
  echo "$TOKEN" > "$TOKEN_FILE"
  echo "Token saved to ${TOKEN_FILE}: ${TOKEN:0:10}..."
else
  echo "Failed to get token. Response: $TOKEN_RESPONSE"
fi

# Safety: If file empty, error (but continue)
if [ ! -s "$TOKEN_FILE" ]; then
  echo "Token file empty, regenerating..."
  TOKEN_RESPONSE=$(curl -s -u "${ADMIN_CREDENTIALS}" -X POST "http://localhost:9000/api/user_tokens/generate?name=${TOKEN_NAME}")
  TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
  echo "$TOKEN" > "$TOKEN_FILE"
  echo "Regenerated and saved."
fi

# Wait for background process
wait $SQ_PID