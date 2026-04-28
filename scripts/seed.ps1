Write-Host "Seeding database..." -ForegroundColor Cyan
docker exec rythmify_backend npm run seed:assets -- --reset-seed-audio
Write-Host "Seeding complete." -ForegroundColor Green