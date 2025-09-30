#!/bin/bash
set -e

# Configuration
SONARQUBE_URL="http://localhost:9000"
PROJECT_KEY="demo-ecommerce"
PROJECT_NAME="Demo E-commerce"
TOKEN_NAME="gradle-token"
TOKEN_FILE="/imports/sonarqube/sonar-token.txt"
ADMIN_PASSWORD="${SONARQUBE_ADMIN_PASSWORD:-MySecurePoCPass123!}"

echo "Starting SonarQube initialization..."

# Start SonarQube in background
echo "Starting SonarQube..."
java -jar /opt/sonarqube/lib/sonarqube.jar -Dsonar.log.console=true &
SQ_PID=$!

# Wait for SonarQube to be ready
echo "Waiting for SonarQube to start..."
for i in {1..30}; do
    if curl -s -f "$SONARQUBE_URL/api/system/status" | grep -q '"status":"UP"'; then
        echo "SonarQube is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Error: SonarQube failed to start in time"
        exit 1
    fi
    sleep 10
done

# Update admin password if using default
echo "Checking admin password..."
if curl -s -f -u "admin:admin" "$SONARQUBE_URL/api/system/status" > /dev/null; then
    echo "Updating default admin password..."
    curl -u "admin:admin" -X POST "$SONARQUBE_URL/api/users/change_password" \
        -d "login=admin" -d "previousPassword=admin" -d "password=$ADMIN_PASSWORD"
    echo "Admin password updated"
fi

# Create project if not exists
echo "Checking project $PROJECT_KEY..."
if ! curl -s -u "admin:$ADMIN_PASSWORD" "$SONARQUBE_URL/api/projects/search?projects=$PROJECT_KEY" | grep -q "\"key\":\"$PROJECT_KEY\""; then
    echo "Creating project $PROJECT_KEY..."
    curl -s -u "admin:$ADMIN_PASSWORD" -X POST "$SONARQUBE_URL/api/projects/create" \
        -d "project=$PROJECT_KEY" -d "name=$PROJECT_NAME"
    echo "Project created"
fi

# Generate or retrieve token
echo "Setting up SonarQube token..."
TOKEN_RESPONSE=$(curl -s -u "admin:$ADMIN_PASSWORD" "$SONARQUBE_URL/api/user_tokens/search?name=$TOKEN_NAME")

if echo "$TOKEN_RESPONSE" | grep -q '"isValid":true'; then
    # Extract existing token
    TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4 | head -1)
    echo "Using existing token"
else
    # Generate new token
    echo "Generating new token..."
    TOKEN_RESPONSE=$(curl -s -u "admin:$ADMIN_PASSWORD" -X POST "$SONARQUBE_URL/api/user_tokens/generate" -d "name=$TOKEN_NAME")
    TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

    if [ -z "$TOKEN" ]; then
        echo "Error: Failed to generate token"
        echo "Response: $TOKEN_RESPONSE"
        exit 1
    fi
    echo "New token generated"
fi

# Save token to file
echo "$TOKEN" > "$TOKEN_FILE"
echo "Token saved to $TOKEN_FILE"

echo "SonarQube initialization completed successfully"

# Keep SonarQube running
wait $SQ_PID