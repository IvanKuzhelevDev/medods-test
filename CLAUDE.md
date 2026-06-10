# CLAUDE.md

Working instructions for this repository (for Claude / any developer). Keep this
in sync when conventions change.

## What this is

API of a task-tracker module for a medical information system (МИС): CRUD tasks,
many-to-many tags (3 protected system tags), and **calendar-style recurring tasks**
with independent per-day state and one-off exceptions.

Stack: **Ruby 3.4, Rails 8.1 (API-only), PostgreSQL 16, RSpec, rswag, Pagy, Docker.**

## Running & testing (everything goes through Docker)

```bash
docker compose up --build      # API at :3000, Swagger at /api-docs
docker compose run --rm web bash -c "bin/rails db:prepare && bundle exec rspec"
docker compose run --rm --no-deps web bundle exec rubocop      # rubocop-rails-omakase
docker compose run --rm --no-deps web bundle exec brakeman -q  # security scan
```

**Environment gotchas (important):**

- `spec/rails_helper.rb` **forces `RAILS_ENV=test`** (hard `=`, not `||=`), because the
  `web` service presets `RAILS_ENV=development`. Don't revert this — specs must use the
  test DB, otherwise host authorization rejects them (403).
- If `docker compose build` complains about **buildx**, build with the legacy builder:
  `DOCKER_BUILDKIT=0 docker build -t test-medods-web .` then `docker compose up`.
  Compose expects the image name `test-medods-web` (project = directory name).
- **Changing the Gemfile** requires rebuilding the image (gems are baked in, not mounted):
  `docker run --rm -v "$PWD":/app -w /app test-medods-web bundle install` then rebuild.
- Migrations: `docker compose run --rm web bin/rails db:migrate` (runs in dev env,
  updates `db/schema.rb`; the test DB is synced by `maintain_test_schema!` on the next
  rspec run).

## Architecture

`Task` is a **series/rule**. Concrete per-day occurrences are **computed on demand** for a
requested window and only **materialized** into `task_occurrences` when an occurrence
diverges (completed, rescheduled, cancelled). This solves the infinity problem, per-day
state, and one-off exceptions.

- `app/services/recurrence/generator.rb` — pure date math: rule + window → dates.
  Types: `once`, `daily` (every n-th), `monthly` (days 1..31), `specific_dates`,
  `parity` (even/odd). Bounded by the window + `MAX_WINDOW_DAYS = 366`.
- `app/services/occurrences/calendar.rb` + `view.rb` — project a window into occurrence
  views (virtual + overlaid exceptions, with filters). Single source of truth for an
  occurrence's representation (the controller reuses it).
- `app/controllers/api/v1/` — thin controllers (`base`, `tasks`, `occurrences`, `tags`,
  `task_tags`); errors via the shared envelope in `BaseController`.
- `app/serializers/` — plain-ruby serializers.

## Conventions & decisions

- **No authentication / no users** — intentionally out of scope.
- **Status** is a plain string with inclusion validation (NOT a Rails enum — `new` would
  clash with `ActiveRecord#new`). Values: `new`, `in_progress`, `done`, `canceled`.
  Transitions are unrestricted by design.
- **Dates** are calendar dates in a single timezone (UTC); time-of-day is `due_time`.
- An **occurrence** is addressed by `(task_id, date)` where `date` is `YYYY-MM-DD`.
  Reschedule changes `scheduled_at` (time) and keeps the anchor `occurrence_date`.
- **System tags** (`отчётность`, `операции`, `звонок`) are seeded and protected at the
  model level (`throw :abort`) → `422` in the API.
- A `TaskOccurrence` can only be materialized on a date that is really on the series
  schedule (validated via the generator).

## Editing rules

- Follow **TDD**; keep commits atomic and in English, ending with the
  `Co-Authored-By: Claude ...` trailer.
- Keep rubocop (omakase) and brakeman clean; run the full spec suite before committing.
- Product docs (README, Swagger text) in Russian; code/identifiers/commits in English.
- Swagger is generated from `spec/integration/**` via
  `PATTERN='spec/integration/**/*_spec.rb' bin/rails rswag:specs:swaggerize`.
