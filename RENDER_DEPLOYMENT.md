# Deploying Config Server to Render

This guide walks you through deploying the Config Server to Render.com as a Java web service.

## Prerequisites

1. **GitHub Repository**: Your code should be pushed to GitHub
2. **Render Account**: Sign up at [render.com](https://render.com)
3. **Config Repository**: A separate GitHub repository containing your configuration files
4. **Keystore**: A Base64-encoded keystore for encryption (see below)

## Step 1: Prepare Keystore

### Generate Keystore
```bash
# Generate keystore
keytool -genkeypair -alias config-server-key -keyalg RSA \
  -dname "CN=Config Server,OU=IT,O=MyOrg,L=City,ST=State,C=US" \
  -keypass your-secret-password \
  -keystore server.jks \
  -storepass your-keystore-password \
  -storetype JKS

# Convert to Base64 for Render
# On Linux/Mac:
base64 server.jks > server.jks.base64

# On Windows PowerShell:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("server.jks")) | Out-File -Encoding ASCII server.jks.base64
```

Copy the contents of `server.jks.base64` - you'll need this for Render environment variables.

**Note:** If you don't plan to use encryption in your config files, you can skip keystore generation and leave `KEYSTORE_BASE64` unset. However, any `{cipher}` encrypted values in your configuration will not be decrypted.

## Step 2: Create Web Service in Render

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository containing this config-server
4. Configure the service:
   - **Name**: `config-server` (or your preferred name)
   - **Region**: Choose closest to your users
   - **Branch**: `master` or `main`
   - **Runtime**: **Docker**
   - **Dockerfile Path**: `./Dockerfile`

## Step 3: Configure Environment Variables

Add the following environment variables in Render:

### Required Variables

| Variable | Value | Notes |
|----------|-------|-------|
| `GIT_URI` | `https://github.com/your-username/config-repo` | Your config repository URL |
| `GIT_DEFAULT_LABEL` | `main` | Branch name |
| `KEYSTORE_BASE64` | `<base64-encoded-keystore>` | **REQUIRED for encryption** - Paste the Base64 contents from Step 1 |
| `KEYSTORE_PASSWORD` | `your-keystore-password` | **REQUIRED** - The password you used when creating keystore |
| `KEYSTORE_ALIAS` | `config-server-key` | Alias from keystore generation |
| `SPRING_PROFILES_ACTIVE` | `prod` | Spring profile to use |

**⚠️ IMPORTANT**: If you skip `KEYSTORE_BASE64`, encryption will be disabled and any `{cipher}` values in your config files will fail to decrypt.

### Optional Variables

| Variable | Default | Notes |
|----------|---------|-------|
| `PORT` | `8888` | Render will set this automatically |
| `KEYSTORE_TEMP_PATH` | `/tmp/server.jks` | Path where keystore is written |

## Step 4: Configure Health Check

Render will automatically use the health check defined in the Dockerfile:
- **Health Check Path**: `/actuator/health`
- **Initial Delay**: 60 seconds

## Step 5: Deploy

1. Click **"Create Web Service"**
2. Render will:
   - Clone your repository
   - Build the Docker image
   - Deploy the container
   - Assign a URL like `https://config-server-xxxx.onrender.com`

## Step 6: Verify Deployment

Once deployed, test your config server:

```bash
# Check health
curl https://your-config-server.onrender.com/actuator/health

# Test config retrieval (replace 'api-service' and 'dev' with your actual service/profile)
curl https://your-config-server.onrender.com/api-service/dev
```

## Using SSH for Private Git Repositories

If your config repository is private and you want to use SSH instead of HTTPS:

### 1. Generate SSH Key Pair

```bash
ssh-keygen -t ed25519 -C "config-server" -f config-server-key -N ""
```

### 2. Add Public Key to GitHub

1. Go to your config repository on GitHub
2. Settings → Deploy keys → Add deploy key
3. Paste contents of `config-server-key.pub`
4. ✓ Check "Allow write access" (optional)

### 3. Convert Private Key to Base64

```bash
# Linux/Mac:
base64 config-server-key > config-server-key.base64

# Windows PowerShell:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("config-server-key")) | Out-File -Encoding ASCII config-server-key.base64
```

### 4. Update Environment Variables in Render

Add these additional variables:

| Variable | Value |
|----------|-------|
| `GIT_URI` | `git@github.com:your-username/config-repo.git` |
| `GIT_SSH_KEY_BASE64` | `<base64-encoded-private-key>` |

**Note**: You'll need to update the Dockerfile and add a startup script to write the SSH key to filesystem. This is more complex than using HTTPS with a GitHub personal access token.

## Best Practices for Production

### 1. Use GitHub Personal Access Token (Recommended)

For private repositories, use HTTPS with a Personal Access Token:

```bash
GIT_URI=https://<token>@github.com/your-username/config-repo.git
```

Generate a token: GitHub → Settings → Developer settings → Personal access tokens → Generate new token
- Select `repo` scope
- Copy the token and use it in the GIT_URI

### 2. Secure Your Config Server

**Add Basic Authentication**:

Add these environment variables in Render:

```bash
SPRING_SECURITY_USER_NAME=admin
SPRING_SECURITY_USER_PASSWORD=<strong-password>
```

Update client applications to use:
```yaml
spring:
  cloud:
    config:
      uri: https://admin:password@your-config-server.onrender.com
```

### 3. Monitor Your Service

Enable Render's built-in monitoring:
- View logs: Render Dashboard → Service → Logs
- Check metrics: CPU, Memory usage
- Set up alerts for downtime

### 4. Auto-Deploy

Enable auto-deploy in Render to automatically deploy when you push to GitHub.

## Troubleshooting

### Container Fails to Start

Check logs in Render dashboard. Common issues:
- Invalid keystore password
- Unreachable Git repository
- Out of memory

### "Invalid keystore location" Error

**Error message:**
```
java.lang.IllegalStateException: Invalid keystore location
```

**Causes & Solutions:**

1. **Missing KEYSTORE_BASE64 environment variable**
   - ✅ Ensure `KEYSTORE_BASE64` is set in Render with the complete Base64-encoded keystore
   - ✅ Verify there are no extra spaces or line breaks in the Base64 string

2. **Invalid Base64 encoding**
   - ✅ Re-encode the keystore: `base64 server.jks | tr -d '\n' > server.jks.base64`
   - ✅ Copy the entire contents without any formatting

3. **Missing KEYSTORE_PASSWORD**
   - ✅ Verify `KEYSTORE_PASSWORD` matches the password used when creating the keystore

4. **Permission issues**
   - ✅ The application runs as a non-root user with write access to `/tmp`
   - ✅ This should work by default in the Dockerfile

**How to verify your keystore locally:**
```bash
# Test decode your Base64 keystore
echo "$KEYSTORE_BASE64" | base64 -d > test-decoded.jks

# Verify it's a valid keystore
keytool -list -keystore test-decoded.jks -storepass your-password
```

### Can't Connect to Config Repository

- Verify `GIT_URI` is correct
- For private repos, ensure token/SSH key has access
- Check `GIT_DEFAULT_LABEL` matches your branch name

### Encryption Errors

- Verify `KEYSTORE_BASE64` is correctly encoded
- Ensure `KEYSTORE_PASSWORD` matches the password used during keystore generation
- Check `KEYSTORE_ALIAS` is correct

## Cost Optimization

Render's free tier includes:
- 750 hours/month of free usage
- Service spins down after 15 minutes of inactivity
- On free tier, first request after inactivity takes 30-60 seconds

For production:
- Use **Starter** plan ($7/month) or higher
- Keeps service always running
- Better for production applications

## Next Steps

After deploying the config server:
1. Update your microservices to point to the Render URL
2. Test fetching configurations from different profiles
3. Set up CI/CD for automatic deployments
4. Monitor logs and performance
