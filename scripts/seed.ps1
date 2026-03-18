Write-Host "Seeding database..." -ForegroundColor Cyan
docker cp ../backend/seeds/seed.sql rythmify_db:/seed.sql
docker exec rythmify_db psql -U dev -d rythmify_dev -f /seed.sql
Write-Host "Seeding complete." -ForegroundColor Green