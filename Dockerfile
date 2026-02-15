# Multi-stage build
FROM eclipse-temurin:21-jdk AS build

WORKDIR /app

# Copy Maven wrapper and pom.xml
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Download dependencies (cached if pom.xml unchanged)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src src

# Build the application
RUN ./mvnw clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre

WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN addgroup --system spring && adduser --system spring --ingroup spring
USER spring:spring

# Create .ssh directory and set permissions
RUN mkdir -p ~/.ssh && chmod 700 ~/.ssh

# Copy SSH keys (if they exist - mount them in docker-compose.yml)
# COPY --chown=spring:spring .ssh/ ~/.ssh/ 2>/dev/null || true

# Copy the JAR file
COPY --from=build /app/target/*.jar app.jar

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8888/actuator/health || exit 1

# Expose port
EXPOSE 8888

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]