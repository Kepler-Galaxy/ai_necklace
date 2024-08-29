# Deployment
1. SCP securety-related files to remote server
scp .env credentials.json docker-compose.yml root@123.456.789.123:/deployment

2. ssh into remote server
ssh root@123.456.789.123
cd deployment

3. use docker-compose to launch services
sudo docker-compose up