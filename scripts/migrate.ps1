Write-Host "Running database migrations..." -ForegroundColor Cyan
docker exec rythmify_backend npm run migrate:up
Write-Host "Migrations complete." -ForegroundColor Green