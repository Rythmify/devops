#!/bin/bash
echo 'Building Rythmify containers...'
docker compose -f docker/docker-compose.yml --env-file environments/.env build --no-cache
docker compose -f docker/docker-compose.backend.yml --env-file environments/.env build --no-cache
docker compose -f docker/docker-compose.frontend.yml --env-file environments/.env build --no-cache
echo 'Build complete.'
