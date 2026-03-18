#!/bin/bash
echo 'Ensuring infrastructure is running...'
docker compose -f docker/docker-compose.yml --env-file environments/.env up -d
echo 'Starting frontend...'
docker compose -f docker/docker-compose.frontend.yml --env-file environments/.env up -d
echo 'Frontend running!'
echo 'Frontend: http://localhost:5173'
