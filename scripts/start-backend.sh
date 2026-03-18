#!/bin/bash
echo 'Starting backend...'
docker compose -f docker/docker-compose.backend.yml --env-file environments/.env up -d
echo 'Backend running!'
echo 'Backend:  http://localhost:8080/api/v1'
