@echo off
echo Generating keystore for Config Server encryption...

REM Try to find keytool in common locations
set KEYTOOL=keytool
where keytool >nul 2>nul
if %ERRORLEVEL% neq 0 (
    REM Try JDK bin directory
    if exist "C:\Program Files\Java\jdk-25\bin\keytool.exe" (
        set KEYTOOL="C:\Program Files\Java\jdk-25\bin\keytool.exe"
    ) else if exist "C:\Program Files\Java\jdk-21\bin\keytool.exe" (
        set KEYTOOL="C:\Program Files\Java\jdk-21\bin\keytool.exe"
    ) else if exist "C:\Program Files\Java\jdk-17\bin\keytool.exe" (
        set KEYTOOL="C:\Program Files\Java\jdk-17\bin\keytool.exe"
    ) else if exist "C:\Program Files\Java\jdk-11\bin\keytool.exe" (
        set KEYTOOL="C:\Program Files\Java\jdk-11\bin\keytool.exe"
    ) else if exist "C:\Program Files\Java\jdk-8\bin\keytool.exe" (
        set KEYTOOL="C:\Program Files\Java\jdk-8\bin\keytool.exe"
    ) else (
        echo ERROR: keytool not found. Please ensure Java JDK is installed and in PATH.
        echo You can download JDK from: https://adoptium.net/
        pause
        exit /b 1
    )
)

REM Prompt for keystore password
set /p KEYSTORE_PASSWORD="Enter keystore password: "

%KEYTOOL% -genkeypair -alias config-server-key -keyalg RSA ^
  -dname "CN=Config Server,OU=Expensora,O=Expensora,L=City,ST=State,C=US" ^
  -keypass %KEYSTORE_PASSWORD% -keystore server.jks -storepass %KEYSTORE_PASSWORD% ^
  -storetype JKS

if %ERRORLEVEL% equ 0 (
    echo Keystore generated successfully!
    echo Please copy server.jks to src/main/resources/ directory
) else (
    echo ERROR: Failed to generate keystore!
    pause
    exit /b 1
)

pause