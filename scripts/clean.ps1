Write-Host "WARNING: This will delete all Rythmify containers, images, and volumes." -ForegroundColor Red
$confirm = Read-Host "Are you sure? Type 'yes' to confirm"
if ($confirm -ne "yes") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit
}
Write-Host "Stopping and removing containers..." -ForegroundColor Cyan
docker compose -f docker/docker-compose.frontend.yml --env-file environments/.env down -v 2>$null
docker compose -f docker/docker-compose.backend.yml --env-file environments/.env down -v 2>$null
docker compose -f docker/docker-compose.yml --env-file environments/.env down -v 2>$null
Write-Host "Removing images..." -ForegroundColor Cyan
docker rmi rythmify-backend rythmify_frontend 2>$null
Write-Host "Pruning unused Docker resources..." -ForegroundColor Cyan
docker system prune -f
Write-Host "Clean complete. Run build.ps1 to rebuild." -ForegroundColor Green