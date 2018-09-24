# Swagger for Rails 5

This is a project to provide Swagger support inside the [Ruby on Rails](http://rubyonrails.org/) framework.

## Prerequisites
You need to install ruby >= 2.2.2 and run:

```
bundle install
```

## Getting started

## Environmental variables
```
export SERVICE_APPROVAL_DATABASE_USERNAME=<<database_user>>
export SERVICE_APPROVAL_DATABASE_PASSSWORD=<<database_password>>
or
export DATABASE_URL=postgres://pguser:pgpass@localhost/somedatabase
export MANAGEIQ_USER=admin
export MANAGEIQ_PASSWORD=smartvm
export MANAGEIQ_HOST=localhost
export MANAGEIQ_PORT=3000
```

This sample was generated with the [swagger-codegen](https://github.com/swagger-api/swagger-codegen) project.

```
bin/rake db:create db:migrate
bin/rails s
```

To list all your routes, use:

```
bin/rake routes
```
