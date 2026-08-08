# 1.9 — unit tests (dbt >= 1.8) run as part of `dbt build` below.
FROM ghcr.io/dbt-labs/dbt-postgres:1.9.latest

WORKDIR /usr/app/dbt

# Copy the project. profiles.yml uses env_var('DBT_HOST') so host is overridable.
COPY dbt_project.yml profiles.yml ./
COPY models ./models
COPY tests ./tests

# Generate docs at startup (so they reflect the live database), then serve.
# Runs against the postgres service inside the docker network.
ENV DBT_HOST=postgres
ENV DBT_PROFILES_DIR=/usr/app/dbt

EXPOSE 8080

CMD ["sh", "-c", "dbt deps --quiet || true && dbt build && dbt docs generate && dbt docs serve --port 8080 --no-browser"]
