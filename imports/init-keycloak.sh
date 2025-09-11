#!/bin/bash
# init-keycloak.sh

# Wait for Keycloak to be ready
until curl -s http://localhost:8080/realms/master > /dev/null; do
  echo "Waiting for Keycloak to be ready ..."
  sleep 2
done

# SSL None configure
/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin
/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE

echo "Keycloak initialized correctly"