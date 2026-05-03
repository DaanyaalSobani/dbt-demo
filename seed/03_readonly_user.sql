-- Read-only user for pgweb / hosted data explorer.
-- Created after schemas/tables exist (file naming order matters).

create user explorer with password 'explorer';
grant connect on database dbt_demo to explorer;

-- Existing schemas (raw is created by 01_schema.sql, all tables seeded by 02)
grant usage on schema raw to explorer;
grant select on all tables in schema raw to explorer;
alter default privileges in schema raw grant select on tables to explorer;
alter default privileges for role dbt in schema raw grant select on tables to explorer;

-- dbt will create these later; pre-grant default privileges so it Just Works
create schema if not exists analytics;
grant usage on schema analytics to explorer;
grant select on all tables in schema analytics to explorer;
alter default privileges in schema analytics grant select on tables to explorer;
-- The dbt user owns the analytics schema; ensure tables it creates inherit the grant
alter default privileges for role dbt in schema analytics grant select on tables to explorer;
