Write-Host "Ensuring infrastructure is running..." -ForegroundColor Cyan
docker compose -f docker/docker-compose.yml --env-file environments/.env up -d
Write-Host "Starting frontend..." -ForegroundColor Cyan
docker compose -f docker/docker-compose.frontend.yml --env-file environments/.env up -d
Write-Host "Frontend running!" -ForegroundColor Green
Write-Host "Frontend: http://localhost:5173" -ForegroundColor Yellow