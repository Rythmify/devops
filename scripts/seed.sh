#!/bin/bash
echo 'Seeding database...'
docker cp ../backend/seeds/seed.sql rythmify_db:/seed.sql
docker exec rythmify_db psql -U dev -d rythmify_dev -f /seed.sql
echo 'Seeding complete.'
