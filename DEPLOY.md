# Veil Web — Docker & Deployment Guide

The Rails 8 face of Veil: UI, users, gallery, jobs (Solid Queue), Postgres.
Heavy lifting (encode/decode/analyze) is delegated to **veil-core** over HTTP;
results come back asynchronously to `/callbacks/*` (see `../veil-core/DEPLOY.md`
for the core half and the architecture diagram).

File map:

| File | Purpose |
|---|---|
| `docker/dev.yml` | local dev stack: postgres + rails (`be`) + solid-queue (`jobs`) + dartsass (`scss`) |
| `docker/dockerfiles/be.Dockerfile` | dev base image (gems install into the `be_gems` volume at runtime) |
| `docker/dockerfiles/prod.Dockerfile` | production image (Thruster + Puma, port 80) |
| `docker/secret-envs/*.env` | DB creds + core tokens; `*production.env` + `docker-hub.env` are **git-crypt encrypted** |
| `config/deploy.yml` | Kamal: web + job roles, Postgres accessory, volumes, `APP_HOST` |
| `.kamal/secrets` | maps env vars → Kamal secrets (values from the files above + `config/credentials/production.key`) |
| `db/production.sql` | initdb script for the Postgres accessory (creates the Solid cache/queue/cable DBs) |

> **git-crypt:** clone on a new machine → `git-crypt unlock <keyfile>` first,
> otherwise the production env files are ciphertext and `bin/kamal` fails.

---

## 1. Run locally in Docker (first time ever)

Prereqs: Docker Desktop running; repo git-crypt unlocked.

```bash
cd ~/Projects/veil-web

# one-time: the gem + postgres volumes are declared `external`
docker volume create veil_web_be_gems
docker volume create veil_web_postgres

docker compose -f docker/dev.yml up --build
```

What happens on the first run:
1. Postgres boots; compose waits until `pg_isready` (healthcheck).
2. `be` runs `bundle install` (slow once — gems persist in `veil_web_be_gems`),
   `db:create`, `db:migrate`, then `rails server` on `http://localhost:3000`.
3. `jobs` (Solid Queue) and `scss` (dartsass watcher) start only after `be`
   answers `/up` — so they never race the shared gems volume.

Seed users (`bin/rails db:seed`, idempotent): `admin@veil.local / password`
and `user@veil.local / password`.

Reaching veil-core from docker-dev: the containers can see your host as
`host.docker.internal`, so if core runs bare on the host set
`VEIL_CORE_ADDRESS=http://host.docker.internal` in `docker/secret-envs/veil-core.env`
(when both run bare via `bin/dev`, the default `http://localhost` is right).

### Daily driving

```bash
docker compose -f docker/dev.yml up -d        # start (detached)
docker compose -f docker/dev.yml logs -f be   # tail rails
docker compose -f docker/dev.yml restart jobs
docker compose -f docker/dev.yml stop         # stop, keep containers
docker compose -f docker/dev.yml down         # remove containers (gems + db volumes survive)
docker compose -f docker/dev.yml exec be bin/rails console
docker compose -f docker/dev.yml up --build   # after changing be.Dockerfile
# full DB reset: docker volume rm veil_web_postgres (after `down`), recreate, up
```

---

## 2. One-time server preparation

Same as core: an Ubuntu VPS with root SSH key, Docker installed
(`curl -fsSL https://get.docker.com | sh`), ports **22** and **80** open
(Postgres binds to the server's loopback only). Kamal runs locally through the
bundle: `bin/kamal version`.

---

## 3. First deploy — bare IP, no domain

### 3.1 Fill in the placeholders

* `config/deploy.yml` — replace every `WWW.WWW.WWW.WWW` with the **web server
  IP** (web role, job role, db accessory host) and set
  `APP_HOST: WEB_IP` (used by mailer links **and** Turbo broadcast image URLs —
  without it, live-updated cards render `example.com` srcs).
* `docker/secret-envs/veil-core-production.env` — `VEIL_CORE_ADDRESS=http://CORE_IP`,
  `VEIL_CORE_PORT=80` (requests go through core's kamal-proxy, not :8000), and
  the two tokens **identical to veil-core's** copy of this file.
* `docker/secret-envs/postgres-credentials-production.env` +
  `database-production.env` — pick a real password; host stays `veil-web-db`
  (the accessory's container name on the kamal docker network).
* `docker/secret-envs/docker-hub.env` — Docker Hub access token.
* `config/credentials/production.key` must exist (it does; never commit it) —
  `.kamal/secrets` reads `RAILS_MASTER_KEY` from it.

No `proxy:` section = catch-all routing on port 80 → `http://WEB_IP/` works
without a domain. (Sharing one server with core? → nip.io hosts, §7 of the
core guide.)

### 3.2 Ship it

```bash
cd ~/Projects/veil-web
bin/kamal setup
```

`setup` = build + push the image, install kamal-proxy, boot the **veil-web-db**
Postgres accessory (initdb runs `db/production.sql` → creates the
cache/queue/cable databases; the primary comes from `POSTGRES_DB`), then start
the `web` and `job` roles. On boot the entrypoint runs `db:prepare`, which
migrates all four databases and seeds the users above — **log in and change the
seeded passwords immediately.**

### 3.3 Verify

```bash
curl -I http://WEB_IP/up            # 200
open http://WEB_IP                  # sign in: admin@veil.local / password
bin/kamal app logs -r job           # Solid Queue workers polling
```

End-to-end: upload a cover → Encode → the card should flip to SUCCEEDED live
(core called back; check core's §3.4 if it stays processing).

---

## 4. Every next deploy (code changed)

```bash
bin/kamal deploy
```

Pending migrations run automatically on boot (`db:prepare` in the entrypoint).

```bash
bin/kamal console    # rails console on the server
bin/kamal dbc        # rails dbconsole
bin/kamal logs       # tail web logs
bin/kamal shell      # bash in the app container
bin/kamal rollback <version>
```

---

## 5. Stop / start / restart in production

```bash
bin/kamal app stop | start
bin/kamal app boot                 # restart with the same image
bin/kamal app boot -r job          # just the Solid Queue role
bin/kamal accessory reboot db      # Postgres restart (brief downtime)
bin/kamal accessory logs db
```

Data that must survive: Postgres lives in the accessory's host directory
(managed by Kamal), uploaded images in the `veil_web_storage` docker volume —
both untouched by deploys. Quick DB backup from your machine:

```bash
ssh root@WEB_IP 'docker exec veil-web-db pg_dump -U veil_web veil_web_production' > backup.sql
```

---

## 6. Troubleshooting

| Symptom | Look at / fix |
|---|---|
| `setup` dies at "container not healthy" | `bin/kamal app logs --lines 200` — usually DB creds mismatch between the two postgres env files |
| 502 from the IP | `bin/kamal app details`; `bin/kamal proxy logs` |
| Encode stays "processing" forever | job role running? core reachable? token mismatch? `bin/kamal app logs -r job`, then core guide §8 |
| Broadcast cards show broken images | `APP_HOST` not set to the real IP/host in deploy.yml |
| Mails (password reset) in prod | no SMTP configured yet — dev uses letter_opener at `/letter_opener`; wire `smtp_settings` in production.rb when needed |
| Deploy reads garbage env values | repo git-crypt **locked** — `git-crypt unlock`, retry |
| `/jobs` dashboard | admin-only (Mission Control), sign in as an admin user |
