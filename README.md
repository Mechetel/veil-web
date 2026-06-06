# For new application (newer start before)
```
docker volume create veil_web_be_gems
docker volume create veil_web_postgres
docker compose -p dev -f docker/dev.yml up --build
```

# Run application
```
docker compose -p dev -f docker/dev.yml up
```

# Stop application
```
docker compose -p dev -f docker/dev.yml down
```

# Run bundle install
```
docker compose -p dev -f docker/dev.yml run --rm --no-deps be bundle install
```

# Run migration (or any other rails command)
```
docker compose -p dev -f docker/dev.yml run --rm be rails db:migrate
```

# Run rubocop
```
docker compose -p dev -f docker/dev.yml run --rm --no-deps be bundle exec rubocop --parallel
```
