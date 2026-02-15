# Config Server

A Spring Cloud Config Server that serves configuration for multiple applications from a GitHub repository.

## Features

- Fetches configuration from GitHub repository
- Supports multiple applications and profiles
- Encryption support for sensitive data
- RESTful API endpoints for configuration retrieval

## Setup

### 1. Generate Keystore for Encryption

Run the following command to generate a keystore for encrypting sensitive configuration values:

```bash
keytool -genkeypair -alias config-server-key -keyalg RSA \
  -dname "CN=Config Server,OU=Expensora,O=Expensora,L=City,ST=State,C=US" \
  -keypass expensora-secret -keystore server.jks -storepass expensora-config
```

Place the generated `server.jks` file in `src/main/resources/`.

### 2. GitHub Repository Structure

Create a GitHub repository with **one YAML file per service**, where each file contains multiple profiles:

```
config-server-repo/
├── api-service.yml     # Contains dev, release, production profiles for API
├── web-service.yml     # Contains dev, release, production profiles for web
└── batch-service.yml   # Contains dev, release, production profiles for batch
```

### 3. Sample Configuration Files

Each service file uses YAML multi-document format with `---` separators and includes Spring Cloud Config client setup:

#### expensora-api.yml
```yaml
---
spring:
  profiles: dev
  application:
    name: expensora-api
  cloud:
    config:
      uri: ${CONFIG_SERVER_URI:http://localhost:8888}
      fail-fast: true

  datasource:
    url: ${DATABASE_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: ${DDL_AUTO}
    show-sql: ${SHOW_SQL}

jwt:
  secret: ${JWT_SECRET}
  expiration: ${JWT_EXPIRATION}

server:
  port: ${PORT}

---
spring:
  profiles: production
  application:
    name: api-service
  cloud:
    config:
      uri: ${CONFIG_SERVER_URI}

  datasource:
    url: ${DATABASE_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver
    hikari:
      maximum-pool-size: 50

  jpa:
    hibernate:
      ddl-auto: ${DDL_AUTO}
    show-sql: false

jwt:
  secret: ${JWT_SECRET}
  expiration: ${JWT_EXPIRATION}

server:
  port: ${PORT}
  compression:
    enabled: true

# Production settings
springdoc:
  api-docs:
    enabled: false
  swagger-ui:
    enabled: false

logging:
  level:
    com: WARN
```

## 🐳 Docker Deployment

### Build and Run Locally
```bash
# Build the Docker image
docker build -t expensora-config-server .

# Run locally
docker run -p 8888:8888 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e ENCRYPT_KEY=your-encryption-key \
  expensora-config-server
```

### Using Docker Compose
```bash
# Start the config server
docker-compose up -d

# View logs
docker-compose logs -f config-server

# Stop the service
docker-compose down
```

### Deploy to Render with Docker

1. **Create New Render Service**
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click **"New"** → **"Web Service"**
   - Connect your **config-server** GitHub repository
   - Select **"Docker"** as runtime

2. **Configure the Service**
   - **Name:** `expensora-config-server`
   - **Dockerfile Path:** `./Dockerfile`
   - **Branch:** `main`

3. **Set Environment Variables**
   ```bash
   SPRING_PROFILES_ACTIVE=prod
   ENCRYPT_KEY=your-generated-encryption-key
   ```

4. **Deploy**
   - Click **"Create Web Service"**
   - Render will build and deploy using Docker

## 🔐 Generate Encryption Key

```bash
# Generate a secure 256-bit key
openssl rand -hex 32
```

Use this key as your `ENCRYPT_KEY` environment variable.

## API Endpoints

- `GET /{application}/{profile}` - Get configuration for an application and profile
- `GET /{application}/{profile}/{label}` - Get configuration with specific Git label
- `POST /encrypt` - Encrypt a value
- `POST /decrypt` - Decrypt a value

## Client Configuration

Configure your Spring Boot applications to use this config server by creating a `bootstrap.yml` file:

### For API Service:
```yaml
# src/main/resources/bootstrap.yml
spring:
  application:
    name: api-service
  profiles:
    active: dev  # Change to 'release' or 'production'
  cloud:
    config:
      uri: ${CONFIG_SERVER_URI:http://localhost:8888}
      fail-fast: true
      retry:
        max-attempts: 10
        initial-interval: 1000
        max-interval: 2000
        multiplier: 1.1
```

### Environment Variables to Set:

**For Local Development:**
```bash
CONFIG_SERVER_URI=http://localhost:8888
DATABASE_URL=jdbc:postgresql://localhost:5432/expensora_dev
DB_USERNAME=your_db_user
DB_PASSWORD=your_db_password
JWT_SECRET=your_jwt_secret
JWT_EXPIRATION=86400000
JWT_REFRESH_EXPIRATION=604800000
PORT=8080
CORS_ALLOWED_ORIGINS=http://localhost:3000
DDL_AUTO=update
SHOW_SQL=true
```

**For Production (Render):**
```bash
CONFIG_SERVER_URI=https://your-config-server.onrender.com
DATABASE_URL=your_production_db_url
DB_USERNAME=your_prod_db_user
DB_PASSWORD=your_prod_db_password
JWT_SECRET=your_prod_jwt_secret
JWT_EXPIRATION=86400000
JWT_REFRESH_EXPIRATION=604800000
PORT=10000
CORS_ALLOWED_ORIGINS=https://your-frontend-domain.com
DDL_AUTO=validate
SHOW_SQL=false
```

## Encryption

To encrypt sensitive values:

```bash
curl -X POST http://localhost:8888/encrypt -d mysecret
```

Use the encrypted value in your YAML files with `{cipher}` prefix:

```yaml
database:
  password: '{cipher}encrypted_value_here'
```