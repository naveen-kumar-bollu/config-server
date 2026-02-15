# Config Server

A Spring Cloud Config Server that serves configuration for multiple applications from a GitHub repository. This server supports encryption, multiple profiles, and can be easily deployed to cloud platforms like Render.

## Features

- ✅ Fetches configuration from GitHub repository  
- ✅ Supports multiple applications and profiles
- ✅ Encryption support for sensitive data using keystore
- ✅ RESTful API endpoints for configuration retrieval
- ✅ Docker support with multi-stage builds
- ✅ Production-ready with security, health checks, and monitoring
- ✅ Optimized for Render.com deployment

## Prerequisites

- Java 21 or higher
- Maven 3.6+
- Git
- Docker (optional, for containerized deployment)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/naveen-kumar-bollu/config-server.git
cd config-server
```

### 1. Generate Keystore for Encryption

Generate a keystore to encrypt sensitive configuration values:

**Linux/Mac:**
```bash
keytool -genkeypair -alias config-server-key -keyalg RSA \
  -dname "CN=Config Server,OU=IT,O=MyOrg,L=City,ST=State,C=US" \
  -keypass your-secret-password -keystore server.jks -storepass your-keystore-password
```

**Windows:**
```bash
scripts\generate-keystore.bat
```

Place the generated `server.jks` file in the `keystore/` directory.

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and update with your values:

```bash
cp .env.example .env
```

Edit `.env`:
```properties
KEYSTORE_PASSWORD=your-keystore-password
KEYSTORE_ALIAS=config-server-key
GIT_REPO_URI=https://github.com/your-username/config-repo.git
GIT_DEFAULT_LABEL=main
```

### 3. Run Locally

**Using Maven:**
```bash
mvn spring-boot:run
```

**Using Java:**
```bash
mvn clean package
java -jar target/config-server-0.0.1-SNAPSHOT.jar
```

The server will start on `http://localhost:8888`

## Configuration Repository Structure

Create a GitHub repository with **one YAML file per service**, where each file contains multiple profiles:

```
config-repo/
├── api-service.yml       # API service configurations
├── web-service.yml       # Web service configurations
└── batch-service.yml     # Batch service configurations
```

See `sample-configs/` directory for examples.

## API Endpoints

### Configuration Endpoints
- `GET /{application}/{profile}` - Get configuration for an application and profile
- `GET /{application}/{profile}/{label}` - Get configuration with specific Git label/branch
- `GET /{label}/{application}-{profile}.yml` - Get raw YAML file

### Encryption Endpoints (Requires Authentication)
- `POST /encrypt` - Encrypt a value
- `POST /decrypt` - Decrypt a value

### Monitoring Endpoints
- `GET /actuator/health` - Health check (public)
- `GET /actuator/info` - Application info (public)

### Example Requests

```bash
# Get configuration for api-service in dev profile
curl http://localhost:8888/api-service/dev

# Get configuration for production profile from specific branch
curl http://localhost:8888/api-service/production/release-1.0

# Encrypt a value (requires authentication)
curl -u admin:password -X POST http://localhost:8888/encrypt -d 'my-secret-value'

# Health check
curl http://localhost:8888/actuator/health
```

## Sample Configuration File

Each service file uses YAML multi-document format with `---` separators:

### api-service.yml
```yaml
---
spring:
  profiles: dev
  application:
    name: api-service
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

### Build Docker Image
```bash
docker build -t config-server .
```

### Run with Docker
```bash
docker run -p 8888:8888 \
  -e GIT_URI=https://github.com/your-username/config-repo \
  -e KEYSTORE_PASSWORD=your-password \
  -e KEYSTORE_BASE64="<base64-encoded-keystore>" \
  config-server
```

### Using Docker Compose

1. Update environment variables in `docker-compose.yml`
2. Start the service:

```bash
docker-compose up -d

# View logs
docker-compose logs -f config-server

# Stop the service
docker-compose down
```

## ☁️ Deploy to Render

See [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md) for detailed instructions on deploying to Render.com.

**Quick Steps:**
1. Push your code to GitHub
2. Create a new Web Service in Render
3. Select Docker runtime
4. Configure environment variables (see RENDER_DEPLOYMENT.md)
5. Deploy!

Your config server will be available at `https://your-service.onrender.com`

## 🔐 Security

### Authentication

The config server uses HTTP Basic Authentication. Set credentials using environment variables:

```bash
SPRING_SECURITY_USER_NAME=admin
SPRING_SECURITY_USER_PASSWORD=your-secure-password
```

### Encryption

To encrypt sensitive values in your configuration files:

```bash
# Encrypt a value
curl -u admin:password -X POST http://localhost:8888/encrypt -d 'my-secret-value'
# Returns: AQBkKpHcD8fF8rK...

# Use encrypted value in YAML with {cipher} prefix
database:
  password: '{cipher}AQBkKpHcD8fF8rK...'
```

### Generate Secure Keys

```bash
# Generate keystore password
openssl rand -base64 32

# Generate encryption key
openssl rand -hex 32
```

## Client Configuration

Configure your Spring Boot applications to use this config server:

### Maven Dependency

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-config</artifactId>
</dependency>
```

### Application Configuration

Create `application.yml` in your client application:

```yaml
spring:
  application:
    name: api-service  # Must match config file name in repo
  profiles:
    active: dev  # Can be: dev, staging, production
  config:
    import: "optional:configserver:http://localhost:8888"
  cloud:
    config:
      uri: ${CONFIG_SERVER_URI:http://localhost:8888}
      username: ${CONFIG_SERVER_USERNAME:admin}
      password: ${CONFIG_SERVER_PASSWORD:your-password}
      fail-fast: true
      retry:
        max-attempts: 6
        initial-interval: 1000
        max-interval: 2000
        multiplier: 1.1
```

### Environment Variables for Client Apps

**Local Development:**
```properties
CONFIG_SERVER_URI=http://localhost:8888
CONFIG_SERVER_USERNAME=admin
CONFIG_SERVER_PASSWORD=your-password
```

**Production (Render/Cloud):**
```properties
CONFIG_SERVER_URI=https://your-config-server.onrender.com
CONFIG_SERVER_USERNAME=admin
CONFIG_SERVER_PASSWORD=your-production-password
```

## 🧪 Testing

### Run Tests
```bash
mvn test
```

### Manual Testing
```bash
# Start the server
mvn spring-boot:run

# In another terminal, test endpoints
curl http://localhost:8888/actuator/health

# Test config retrieval (update with your service name)
curl -u admin:password http://localhost:8888/api-service/dev
```

## 📊 Monitoring

The config server exposes actuator endpoints for monitoring:

- `/actuator/health` - Health status
- `/actuator/info` - Application information

For production, configure additional monitoring through your cloud provider.

## 🔧 Troubleshooting

### Common Issues

**1. Cannot connect to Git repository**
- Verify `GIT_URI` is correct and accessible
- For private repos, use HTTPS with Personal Access Token
- Check network connectivity

**2. Encryption/Decryption errors**
- Verify keystore password matches the one used during generation
- Ensure `KEYSTORE_BASE64` is properly encoded
- Check keystore alias is correct

**3. Config not refreshing**
- Config server caches configurations
- Restart the config server to force refresh
- Or use Spring Cloud Bus for dynamic refresh

**4. Authentication failures**
- Verify username and password are set correctly
- Check client applications are using correct credentials

## 📁 Project Structure

```
config-server/
├── src/
│   ├── main/
│   │   ├── java/com/configserver/
│   │   │   ├── ConfigServerApplication.java
│   │   │   ├── SecurityConfig.java
│   │   │   └── KeystoreDecoder.java
│   │   └── resources/
│   │       └── application.yml
│   └── test/
├── sample-configs/          # Example configuration files
├── scripts/                 # Utility scripts
├── keystore/               # Store your keystore here (gitignored)
├── Dockerfile
├── docker-compose.yml
├── render.yaml             # Render deployment config
└── README.md
```

## 📚 Additional Resources

- [Spring Cloud Config Documentation](https://docs.spring.io/spring-cloud-config/docs/current/reference/html/)
- [Render Deployment Guide](RENDER_DEPLOYMENT.md)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)

## 📄 License

This project is available under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📬 Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues and documentation
- Review the troubleshooting section above