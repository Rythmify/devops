#!/bin/bash
read -p 'WARNING: This will delete all data. Type yes to confirm: ' confirm
if [ "$confirm" != "yes" ]; then
  echo 'Cancelled.'
  exit 0
fi
echo 'Stopping and removing containers...'
docker compose -f docker/docker-compose.frontend.yml --env-file environments/.env down -v 2>/dev/null
docker compose -f docker/docker-compose.backend.yml --env-file environments/.env down -v 2>/dev/null
docker compose -f docker/docker-compose.yml --env-file environments/.env down -v 2>/dev/null
echo 'Removing images...'
docker rmi rythmify-backend rythmify_frontend 2>/dev/null
docker system prune -f
echo 'Clean complete. Run build.sh to rebuild.'
