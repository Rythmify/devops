Write-Host "Building Rythmify containers..." -ForegroundColor Cyan
docker compose -f docker/docker-compose.yml --env-file environments/.env build --no-cache
Write-Host "Build complete." -ForegroundColor Green