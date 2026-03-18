Write-Host "Ensuring infrastructure is running..." -ForegroundColor Cyan
docker compose -f docker/docker-compose.yml --env-file environments/.env up -d
Write-Host "Starting backend..." -ForegroundColor Cyan
docker compose -f docker/docker-compose.backend.yml --env-file environments/.env up -d
Write-Host "Backend running!" -ForegroundColor Green
Write-Host "Backend:  http://localhost:8080/api/v1" -ForegroundColor Yellow