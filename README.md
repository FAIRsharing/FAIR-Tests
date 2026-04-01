# FAIR Tests API 

## About

This is a simple Sinatra application which provies a REST API (only, no GUI) for running
FAIR tests.

See also: https://champion.fairsharing.org

## Structure

* fair_tests.rb - the main application file. Run with `rackup`.
* lib/ - contains the FAIR tests, one file per test.
* test/ - contains unit tests for the application. Run these with `rake test`.
* test/fixtures - contains test data, e.g. example JSON files from ORA.

### Adding tests

These should go in test/ and be named after the relevant FAIR test, e.g. 
test/ft_m_r1.2_original_source. This can be run by posting the relevant ID to the test route:

```
POST /test/ft_m_r1.2_original_source { "resource_identifier": "id_goes_here" }
```

## Setup

First, install rvm: https://rvm.io/rvm/install

There are .ruby-version and .ruby-gemset files in the root directory, so 
`cd ..; cd -` should activate the required ruby version and gemset.

Run `gem install bundler` and `bundle install` to install the required gems.

Run the application with `rerun 'rackup'`.

## Deployment

Probably a Systemd service for fair_tests.rb, with an Nginx proxy (TODO).
