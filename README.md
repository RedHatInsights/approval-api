# OpenAPI for Rails 5

[![Build Status](https://travis-ci.org/ManageIQ/approval-api.svg)](https://travis-ci.org/ManageIQ/approval-api)
[![Maintainability](https://api.codeclimate.com/v1/badges/01ea4517f71f0df102d2/maintainability)](https://codeclimate.com/github/ManageIQ/approval-api/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/01ea4517f71f0df102d2/test_coverage)](https://codeclimate.com/github/ManageIQ/approval-api/test_coverage)
[![Security](https://hakiri.io/github/ManageIQ/approval-api/master.svg)](https://hakiri.io/github/ManageIQ/approval-api/master)


This is a project to provide OpenAPI support inside the [Ruby on Rails](http://rubyonrails.org/) framework.

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

```
bin/rake db:create db:migrate
bin/rails s
```

To list all your routes, use:

```
bin/rake routes
```

## License

This project is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
