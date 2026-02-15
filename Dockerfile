# Multi-stage build
FROM eclipse-temurin:21-jdk AS build

WORKDIR /app

# Install Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src src

# Build the application
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre

WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN addgroup --system spring && \
    adduser --system --home /home/spring spring --ingroup spring && \
    mkdir -p /home/spring && \
    chown spring:spring /home/spring
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