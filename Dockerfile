# multistage Dockerfile
# stage 1 builds the Spring Boot app with Maven; stage 2 is a minimal runtime image.
# Modernized 2026-07: AdoptOpenJDK (archived -> Eclipse Temurin) and UBI 8.4 -> UBI 9.
### stage 1: build ###
FROM maven:3.9-eclipse-temurin-11 AS builder

WORKDIR /workspace/app

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src

RUN mvn package -DskipTests

### stage 2: runtime ###
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf install -y java-11-openjdk-headless && microdnf clean all

COPY --from=builder /workspace/app/target/*.jar ./app.jar

EXPOSE 8080/tcp
USER 1001

CMD ["java", "-jar", "./app.jar"]
