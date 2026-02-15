@echo off
echo Generating SSH key pair for Config Server Git access...

REM Create .ssh directory if it doesn't exist
if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh"

REM Generate SSH key pair (no passphrase for automation)
ssh-keygen -t rsa -b 4096 -C "config-server-deploy-key" -f "%USERPROFILE%\.ssh\config-server-key" -N ""

echo SSH key pair generated successfully!
echo.
echo PUBLIC KEY (add this to GitHub repository deploy keys):
echo ====================================================
type "%USERPROFILE%\.ssh\config-server-key.pub"
echo ====================================================
echo.
echo INSTRUCTIONS:
echo 1. Copy the public key above
echo 2. Go to https://github.com/naveen-kumar-bollu/config-server-repo/settings/keys
echo 3. Click "Add deploy key"
echo 4. Title: "Config Server Deploy Key"
echo 5. Paste the public key
echo 6. Check "Allow write access" if needed (usually read-only is sufficient)
echo 7. Click "Add key"
echo.
echo The private key will be used by the config server automatically.
echo Make sure the repository is set to PRIVATE in GitHub settings.

pause