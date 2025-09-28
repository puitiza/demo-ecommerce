#!/usr/bin/env bash
# ./imports/scripts/update-compose.sh
# Updates docker-compose.yml to use the specified version for the custom services.
# Assumes the file has 'build:' blocks to remove and adds 'image:' with ghcr.io/puitiza/demo-ecommerce-<service>:<version>.

set -e

VERSION=$1
SERVICES=("server-gateway" "server-discovery" "server-config" "product-service" "order-service")
COMPOSE_FILE="docker-compose.yml"

# Backup original file
cp "$COMPOSE_FILE" "${COMPOSE_FILE}.bak"

# Use sed to remove build blocks and add image for each service
for SERVICE in "${SERVICES[@]}"; do
    # Remove the entire build block (from 'build:' to the next service or end)
    sed -i "/^  $SERVICE:/,/^(  [a-z-]*:)/s/^\(  $SERVICE:\)\n\(    build:\)\n\(      .*$\n\)*\(    .*\n\)*//" "$COMPOSE_FILE" || true

    # Add image line after the service name
    sed -i "/^  $SERVICE:/a\    image: ghcr.io/puitiza/demo-ecommerce-$SERVICE:$VERSION" "$COMPOSE_FILE"
done

echo "Updated $COMPOSE_FILE with version $VERSION"