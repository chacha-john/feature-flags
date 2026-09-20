# syntax=docker/dockerfile:1

# ---------- Stage 1: build the jar and split it into layers ----------
FROM maven:3.9-eclipse-temurin-17-alpine AS build
WORKDIR /build

COPY pom.xml .
COPY src ./src

# The cache mount keeps ~/.m2 between builds, so dependencies aren't re-downloaded
# when only source code changes. Tests are skipped on purpose: run `mvn test` in CI
# before building the image.
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -ntp -DskipTests package \
 && cp target/*.jar application.jar

# Split the fat jar into layers (dependencies rarely change, application code often).
# mkdir -p guarantees every layer directory exists, even when empty (e.g. no SNAPSHOT deps).
RUN java -Djarmode=tools -jar application.jar extract --layers --destination extracted \
 && mkdir -p extracted/dependencies extracted/spring-boot-loader \
             extracted/snapshot-dependencies extracted/application

# ---------- Stage 2: minimal runtime (JRE only, no Maven, no JDK, no sources) ----------
FROM eclipse-temurin:17-jre-alpine
WORKDIR /application

# Run as an unprivileged user.
RUN addgroup -S app && adduser -S -G app -H app

# Least-changing layers first so rebuilds reuse the cache.
COPY --from=build --chown=app:app /build/extracted/dependencies/ ./
COPY --from=build --chown=app:app /build/extracted/spring-boot-loader/ ./
COPY --from=build --chown=app:app /build/extracted/snapshot-dependencies/ ./
COPY --from=build --chown=app:app /build/extracted/application/ ./

USER app

# Container-aware heap sizing and a lean GC; override at runtime with -e JAVA_TOOL_OPTIONS=...
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError"

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "application.jar"]
