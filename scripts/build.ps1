Write-Host "Building all images..." -ForegroundColor Cyan
docker compose -f docker/docker-compose.yml --env-file environments/.env build --no-cache
docker compose -f docker/docker-compose.backend.yml --env-file environments/.env build --no-cache
docker compose -f docker/docker-compose.frontend.yml --env-file environments/.env build --no-cache
Write-Host "Build complete." -ForegroundColor Green