#!/bin/bash
echo 'Seeding database...'
docker exec rythmify_backend npm run seed:assets -- --reset-seed-audio
echo 'Seeding complete.'
