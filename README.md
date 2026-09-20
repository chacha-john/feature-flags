# feature-flags

A minimal in-memory feature flag service built with Spring Boot 3 and Maven.

## Endpoints

| Method | Path            | Description                                   |
|--------|-----------------|-----------------------------------------------|
| GET    | `/flags`        | List all flags                                |
| GET    | `/flags/{name}` | Get one flag (404 if it doesn't exist)        |
| PUT    | `/flags/{name}` | Create or update a flag (201 new, 200 update) |

`PUT` body: `{"enabled": true, "description": "optional"}`.
If `description` is omitted on an update, the existing one is kept.
Names: lowercase letters, digits, `-` and `_`, up to 64 characters.

Two flags are seeded on startup: `dark-mode` (off) and `new-checkout` (on).

## Storage

| Profile              | Store                | Used for                              |
|----------------------|----------------------|---------------------------------------|
| none (default)       | In memory            | IDE runs, `mvn test`; resets on restart |
| `postgres`           | PostgreSQL via JDBC  | Docker Compose, shared/persistent state |

The `postgres` profile creates the `flags` table and seeds the two flags on startup
(`src/main/resources/db/schema.sql`, idempotent).

## Run

Requires Java 17+ and Maven 3.9+.

```bash
mvn spring-boot:run          # http://localhost:8080
PORT=9000 mvn spring-boot:run
```

## Try it

```bash
curl localhost:8080/flags
curl localhost:8080/flags/dark-mode
curl -X PUT localhost:8080/flags/dark-mode \
     -H 'Content-Type: application/json' -d '{"enabled": true}'
curl -X PUT localhost:8080/flags/beta-search \
     -H 'Content-Type: application/json' \
     -d '{"enabled": false, "description": "Beta search backend"}'
```

## Test and package

```bash
mvn test
mvn package                  # target/feature-flags-1.0.0.jar
java -jar target/feature-flags-1.0.0.jar
```

## Docker

Configuration and credentials live in `.env` (git-ignored). Only `.env.example` is committed.

```bash
cp .env.example .env             # then set POSTGRES_PASSWORD  (e.g. openssl rand -hex 16)
docker compose up --build        # nginx -> app -> postgres
curl localhost:8080/flags        # via nginx
docker compose down              # add -v to also delete the database volume
```

| Variable            | Default | Purpose                                        |
|---------------------|---------|------------------------------------------------|
| `POSTGRES_PASSWORD` | none    | **Required.** Compose refuses to start without it |
| `POSTGRES_USER`     | `flags` | Database user                                  |
| `POSTGRES_DB`       | `flags` | Database name                                  |
| `HTTP_PORT`         | `8080`  | Host port for nginx                            |
| `DB_HOST_PORT`      | `5432`  | Host port for Postgres (bound to 127.0.0.1)    |

- `nginx` is the only service exposed to the host; `app` is reachable only through it.
- To run the app from the IDE against the containerised DB: `docker compose up -d db`, then run
  `FeatureFlagApplication` with `SPRING_PROFILES_ACTIVE=postgres` and matching
  `SPRING_DATASOURCE_USERNAME` / `SPRING_DATASOURCE_PASSWORD` environment variables.
- Postgres only reads `POSTGRES_PASSWORD` when it first creates the data volume. After changing it,
  run `docker compose down -v` (deletes the data) or change it inside the DB with `ALTER USER`.
- Build the image on its own: `docker build -t feature-flags .`
