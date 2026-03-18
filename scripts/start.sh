#!/bin/bash
echo 'Starting Rythmify...'
docker compose -f docker/docker-compose.yml --env-file environments/.env up -d
docker compose -f docker/docker-compose.backend.yml --env-file environments/.env up -d
docker compose -f docker/docker-compose.frontend.yml --env-file environments/.env up -d
echo 'Rythmify is running!'
echo 'Backend:  http://localhost:8080/api/v1'
echo 'Frontend: http://localhost:5173'
echo 'pgAdmin:  http://localhost:5050'
echo 'Azurite:  http://localhost:10000'
