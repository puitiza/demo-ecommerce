#!/usr/bin/env bash
# ./imports/scripts/update-compose.sh
# Updates docker-compose.yml to use the specified version for the custom services.
# Uses yq to safely edit YAML without duplicates.

set -e

VERSION=$1
SERVICES=("server-gateway" "server-discovery" "server-config" "product-service" "order-service")
COMPOSE_FILE="docker-compose.yml"

# Install yq if not present (though it's available on ubuntu-latest)
if ! command -v yq &> /dev/null; then
    sudo snap install yq  # Fallback, but usually not needed in CI
fi

# Backup original file
cp "$COMPOSE_FILE" "${COMPOSE_FILE}.bak"

for SERVICE in "${SERVICES[@]}"; do
    # Remove existing 'build' key and any 'image' key under the service
    yq eval "del(.services.\"$SERVICE\".build)" -i "$COMPOSE_FILE"
    yq eval "del(.services.\"$SERVICE\".image)" -i "$COMPOSE_FILE"

    # Add the new image key
    yq eval ".services.\"$SERVICE\".image = \"ghcr.io/puitiza/demo-ecommerce-$SERVICE:$VERSION\"" -i "$COMPOSE_FILE"
done

echo "Updated $COMPOSE_FILE with version $VERSION"