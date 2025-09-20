#!/bin/sh
set -e

# Replaces the Placeholder in all dashboards
if ls /etc/grafana/dashboards/*.json > /dev/null 2>&1; then
  sed -i -e 's/\${DS_PROMETHEUS}/Prometheus/g' /etc/grafana/dashboards/*.json
fi

# Execute the original grafana entrypoint
/run.sh