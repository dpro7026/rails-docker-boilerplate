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
Visit *localhost:3000* and see the skeleton Rails app is running.</br>
Note: To stop the app use `docker-compose down` and restart it with `docker-compose up`</br>
Check PGAdmin is functional at *localhost:5050* and login using the username and password in the `docker-compose.yml`</br>

## Customising the App to Support Users
Create a controller for a homepage with an index action (with associated view):
```
docker-compose run web rails g controller Homepage index
```
Add a root route:
```
Rails.application.routes.draw do
  root to: 'homepage#index'
end
```
Visit *localhost:3000* to see the new homepage.</br>
Add the Devise gem to the `Gemfile`:
```
# For user authentication
gem 'devise', '~> 4.3'
```
Install the new gem:
```
docker-compose run web bundle install
```
When updating the `Gemfile` you need to rebuild with:
```
docker-compose build
```
Run devise generator (read the instruction output):
```
docker-compose run web rails generate devise:install
```
Add the following to config/environments/development.rb:
```
# define default url options for mailer
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```
Ensure flash messages are enabled in `app/views/layouts/application.html.erb`:
```
...
<body>
  <p class="notice"><%= notice %></p>
  <p class="alert"><%= alert %></p>
  <%= yield %>
</body>
...
```
Generate the user views so they can be customised in the future:
```
docker-compose run web rails generate devise:views
```
Add users with the Devise generator (it generates a use migration file, users routes and more):
```
docker-compose run web rails generate devise User
```
Update the migration file `<timestamp>_devise_create_users.rb` to include firstname and lastname columns:
```
create_table :users do |t|
 ## Adding our own addtional columns to the User table
  t.string :first_name, null: false
  t.string :last_name, null: false

  ## Database authenticatable
  t.string :email,              null: false, default: ""
  t.string :encrypted_password, null: false, default: ""
  ...
```
Run database migrations:
```
docker-compose run web rails db:migrate
```
Create a default development user, in the `db/seeds.rb`:
```
if Rails.env.development?
    User.create!(first_name: 'Harry', last_name: 'Potter', email: 'harrypotter@example.com', password: 'password1', password_confirmation: 'password1')
end
```
Seed the development database:
```
docker-compose run web rails db:seed
```
Need to restart the web app service with:
```
docker-compose down
docker-compose up
```
Visit *localhost:3000* and login with the seed username and password.</br>
Awesome the app is running with a database and a UI for administering the DB!</br>

## Publish the Rails Docker Boilerplate to Docker Hub
Log in to Docker Hub:
```
docker login
```
List the current docker processes running:
```
docker ps
```
Copy the ID for the `rails-docker-boilerplate_web` image and tag the image:
```
docker tag <CONTAINER_ID> <DOCKER_HUB_ID>/rails-docker-boilerplate:1.0
```

## Adding Audit Capabilities
Add PaperTrail gem to the `Gemfile`:
```
# For audit
gem 'paper_trail', '~> 9.2'
```
Run bundle install:
```
docker-compose run web bundle install
```
Rebuild as we updated the `Gemfile`:
```
docker-compose build
```
Add a versions table to the database:
```
docker-compose run web rails generate paper_trail:install
```
Run the migrations:
```
docker-compose run web rails db:migrate
```
Generate a scaffold for Posts:
```
docker-compose run web rails generate scaffold Post title:string content:text
```
Run the migrations:
```
docker-compose run web rails db:migrate
```
As we intend to audit Posts, add to `models/post.rb`:
```
has_paper_trail
```
Add the following to `controllers/application_controller.rb` to track users that made changes:
```
before_action :set_paper_trail_whodunnit
```
