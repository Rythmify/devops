#!/bin/bash
echo 'Stopping Rythmify...'
docker compose -f docker/docker-compose.frontend.yml --env-file environments/.env down
docker compose -f docker/docker-compose.backend.yml --env-file environments/.env down
docker compose -f docker/docker-compose.yml --env-file environments/.env down
echo 'Stopped.'
