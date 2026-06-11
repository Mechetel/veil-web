# veil-web — Rails UI for Veil

Rails 8.1 face of the Veil steganography platform: users, gallery, encode/decode/
analyze flows, live updates. Heavy compute is delegated to **veil-core**
(`~/Projects/veil-core`, FastAPI + Celery) via ActiveResource; results arrive
asynchronously at `/callbacks/*` and reach the browser through per-user Turbo
Stream broadcasts. Postgres + Solid Queue/Cache/Cable, importmap + Stimulus,
dartsass, Active Storage (local disk).

## Ruby environment (required for every shell)

rvm's `rvm use` fails in non-interactive shells — export manually:

```bash
export GEM_HOME=~/.rvm/gems/ruby-3.4.9@veil_web \
       GEM_PATH=~/.rvm/gems/ruby-3.4.9@veil_web:~/.rvm/gems/ruby-3.4.9@global
export PATH="$HOME/.rvm/rubies/ruby-3.4.9/bin:$GEM_HOME/bin:$HOME/.rvm/gems/ruby-3.4.9@global/bin:$PATH"
export DATABASE_USER=postgres DATABASE_PASSWORD=postgres DATABASE_HOST=localhost
```

## Run / test

```bash
bin/dev                                  # foreman: rails :3000 + dartsass:watch + bin/jobs
docker compose -f docker/dev.yml up      # docker alternative (see DEPLOY.md for first-run volumes)
bundle exec rspec                        # full suite (request/model/job specs, FactoryBot)
bin/rails zeitwerk:check                 # autoload sanity
bin/rails dartsass:build                 # compile SCSS once (verify after CSS edits)
bundle exec brakeman -q                  # security scan; reviewed FPs in config/brakeman.ignore
```

Seeds (`db/seeds.rb`, idempotent): `admin@veil.local / password`,
`user@veil.local / password`. Dev mail: `/letter_opener`. Jobs UI: `/jobs`
(Mission Control, admin-only). Deployment: see **DEPLOY.md**.

## Architecture

- **Models**: `User` (roles admin/simple; cover/stego caps 40 + 40, admin
  exempt), `Image` (kind cover|stego, `metadata["model_key"]`), `Embedding`
  (encode op — named so because `Encoding` is a Ruby core class and breaks
  Zeitwerk), `Decoding`, `Analysis`, `Session`/`Current` (Rails 8 auth).
- **`CoreProcessable`** concern (Embedding/Decoding/Analysis): on create →
  `SubmitToCoreJob` + broadcast card; core's callback updates status → concern
  re-broadcasts the replacement card. Streams are per-user:
  `broadcast_*_to [user, "embeddings"]` ↔ `turbo_stream_from Current.user, "embeddings"`.
- **`Veil::Base`** (ActiveResource, pattern copied from frp-uc's Luna): talks to
  core at `VEIL_CORE_ADDRESS:VEIL_CORE_PORT`, `X-Auth-Token` header; resources
  under `Veil::Steganography::*` / `Veil::Steganalysis::*`. Config:
  `config/veil.yml` ← `docker/secret-envs/veil-core*.env`.
- **Callbacks**: `POST /callbacks/steganography|steganalysis` — token-checked
  (`VEIL_CALLBACK_TOKEN`), CSRF-skipped, no session.

## UI conventions (enforced by past review — keep them)

- **Exactly one modal mechanism**: server-rendered into the layout's
  `turbo_frame_tag "remote_modal", target: "_top"` as a native `<dialog>`
  (`shared/_modal` + `modal_controller.js`; triggers via the `delete_link`
  helper → `ConfirmationsController`). No `turbo_confirm`, no JS-built modals,
  no server-side `clear_modal` — closing is client-side (Esc/backdrop/cancel/
  `turbo:submit-end`).
- Flash: fixed top-right toasts; update via `turbo_stream.update("flash", ...)`
  — never `replace` (it destroys the positioned `.flashes` wrapper).
- Show-page deletes: `delete_link(..., navigate: true)` + `?redirect=1` → the
  destroy action redirects to the index (plain non-Turbo submit); list deletes
  stay in-place Turbo Stream removes.
- Bulk select bars (gallery + encode results): checkboxes associate to an
  external empty form via the HTML `form:` attribute (no nested forms);
  action buttons hidden until something is selected; reset on `turbo:submit-end`.
- Broadcast partials render with no request context — URLs need
  `default_url_options` (dev: localhost:3000; prod: `APP_HOST` env). Anything
  with `image_tag`/`url_for` in a broadcast partial breaks silently without it.
- New dataset/scope of images ≠ generalising existing classes — add a new
  class/factory in its own file.

## Secrets

`docker/secret-envs/*production.env` + `docker-hub.env` are **git-crypt
encrypted** and tracked in git on purpose — never gitignore them, never add
`.example` files; new clone → `git-crypt unlock` before `bin/kamal`.
`config/credentials/production.key` stays untracked (read by `.kamal/secrets`).
