#!/bin/bash
set -e

echo "Deployment started..."

git pull origin master
echo "New changes copied to server !"

echo "Installing Dependencies..."
npm install --yes

echo "Creating Production Build..."
npm run build

echo "PM2 Reload"
pm2 reload app_name

echo "Deployment Finished!"
