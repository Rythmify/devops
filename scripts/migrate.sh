#!/bin/bash
echo 'Running database migrations...'
docker exec rythmify_backend npm run migrate:up
echo 'Migrations complete.'
