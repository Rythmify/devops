#!/bin/bash
echo 'Starting infrastructure...'
docker compose -f docker/docker-compose.yml --env-file environments/.env up -d
echo 'Infrastructure running!'
echo 'pgAdmin:  http://localhost:5050'
echo 'Azurite:  http://localhost:10000'
