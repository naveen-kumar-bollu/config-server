# Multi-stage build
FROM eclipse-temurin:21-jdk-jammy AS build

WORKDIR /app

# Install Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Copy pom.xml and download dependencies (cache layer)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src src

# Build the application
RUN mvn clean package -DskipTests

# Runtime stage - using JRE for smaller image
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Install curl for health checks (Render needs this)
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create a non-root user for security
RUN addgroup --system --gid 1001 spring && \
    adduser --system --uid 1001 --home /home/spring --ingroup spring spring && \
    mkdir -p /tmp && \
    chown -R spring:spring /tmp

# Copy entrypoint script and make it executable before switching user
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Switch to non-root user
USER spring:spring

# Copy the JAR file from build stage
COPY --from=build /app/target/*.jar app.jar

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:${PORT:-8888}/actuator/health || exit 1

# Expose port (Render will use PORT env variable)
EXPOSE 8888

# Entrypoint decodes KEYSTORE_BASE64 → file, then launches the JVM
ENTRYPOINT ["/app/docker-entrypoint.sh"]