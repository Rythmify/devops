Write-Host "Starting infrastructure..." -ForegroundColor Cyan
docker compose -f docker/docker-compose.yml --env-file environments/.env up -d
Write-Host "Infrastructure running!" -ForegroundColor Green
Write-Host "pgAdmin:  http://localhost:5050" -ForegroundColor Yellow
Write-Host "Azurite:  http://localhost:10000" -ForegroundColor Yellow