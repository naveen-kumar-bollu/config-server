@echo off
echo Config Server Deployment Script
echo ================================

REM Set environment variables for keystore configuration
set KEYSTORE_LOCATION=file:/app/keystore/server.jks
set KEYSTORE_PASSWORD=your-keystore-password
set KEYSTORE_ALIAS=config-server-key

REM Additional environment variables
set SPRING_PROFILES_ACTIVE=prod
set ENCRYPT_KEY=your-encryption-key

echo Starting Config Server with environment variables:
echo KEYSTORE_LOCATION=%KEYSTORE_LOCATION%
echo KEYSTORE_PASSWORD=%KEYSTORE_PASSWORD%
echo KEYSTORE_ALIAS=%KEYSTORE_ALIAS%

REM Start the services
docker-compose up --build -d

echo.
echo Config Server is starting up...
echo Check status with: docker-compose logs -f config-server
echo Health check: curl http://localhost:8888/actuator/health

pause