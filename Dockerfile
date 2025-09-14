# Build stage
FROM gradle:8.10.2-jdk17 AS builder
ARG MODULE=server-gateway
WORKDIR /app

# Copy only Gradle configuration files first to leverage caching
COPY settings.gradle build.gradle gradle/ /app/
COPY ${MODULE}/build.gradle /app/${MODULE}/build.gradle

# Resolve dependencies
RUN gradle --no-daemon :${MODULE}:dependencies

# Copy source code and build (Execute tests for restdocs)
COPY ${MODULE}/ /app/${MODULE}/
RUN gradle --no-daemon :${MODULE}:bootJar

# Runtime stage
FROM eclipse-temurin:17-jdk
ARG MODULE=server-gateway
WORKDIR /app

# Copy the built JAR
COPY --from=builder /app/${MODULE}/build/libs/*.jar app.jar

# Expose port
ARG PORT=8090
EXPOSE ${PORT}

ENTRYPOINT ["java", "-jar", "app.jar"]