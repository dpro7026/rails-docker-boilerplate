# Rails Docker Boilerplate
## How This App Was Created
Prerequisite: Install Docker on your environment.</br>
Extending the instructions at: [Docker Docs, Quickstart: Compose and Rails](https://docs.docker.com/compose/rails/#define-the-project)
</br>
Create a `Dockerfile` containing:
```
FROM ruby:2.5
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /myapp
WORKDIR /myapp
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
RUN bundle install
COPY . /myapp
```
And a `Gemfile` containing:
```
source 'https://rubygems.org'
gem 'rails', '5.2.0'
```
Create an empty `Gemfile.lock`.</br>
Finally, describe the 3 services - web, postgres and pgadmin by creating a `docker-compose.yml` containing:
```
version: '3'
services:
  postgres:
    container_name: postgres_container
    image: postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-changeme}
      PGDATA: /data/postgres
    volumes:
       - postgres:/data/postgres
    networks:
      - postgres
    restart: unless-stopped

  web:
    build: .
    command: bundle exec rails s -p 3000 -b '0.0.0.0'
    volumes:
      - .:/myapp
    ports:
      - "3000:3000"
    depends_on:
      - postgres
    networks:
      - postgres

  pgadmin:
    container_name: pgadmin_container
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_DEFAULT_EMAIL:-pgadmin4@pgadmin.org}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_DEFAULT_PASSWORD:-admin}
    volumes:
       - pgadmin:/root/.pgadmin
    ports:
      - "${PGADMIN_PORT:-5050}:80"
    networks:
      - postgres
    restart: unless-stopped

networks:
  postgres:
    driver: bridge

volumes:
    postgres:
    pgadmin:

```
Build the rails skeleton app with:
```
docker-compose run web rails new . --force --database=postgresql
```
This will update the `Gemfile` and we need to rebuild the docker file:
```
docker-compose build
```
Connect the database by replacing the contents of `config/database.yml` with:
```
default: &default
  adapter: postgresql
  encoding: unicode
  host: postgres
  username: postgres
  password: changeme
  pool: 5

development:
  <<: *default
  database: myapp_development

test:
  <<: *default
  database: myapp_test
```
Boot the web app with:
```
docker-compose up
```
View the web app at *localhost:3000* but note the error that the development database doesn't exist.</br>
Now create the database:
```
docker-compose run web rails db:create
```
Visit *localhost:3000* and see the skeleton Rails app is running.
