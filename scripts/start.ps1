Write-Host "Starting Rythmify..." -ForegroundColor Cyan
docker compose -f docker/docker-compose.yml --env-file environments/.env up -d
Write-Host "Rythmify is running!" -ForegroundColor Green
Write-Host "Backend:  http://localhost:8080/api/v1" -ForegroundColor Yellow
Write-Host "pgAdmin:  http://localhost:5050" -ForegroundColor Yellow
Write-Host "Azurite:  http://localhost:10000" -ForegroundColor Yellow