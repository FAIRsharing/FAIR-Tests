# FAIR Tests API 

![Tests](https://github.com/FAIRsharing/FAIR-Tests/workflows/Unit%20Tests/badge.svg?branch=main)

[![Coverage Status](https://coveralls.io/repos/github/FAIRsharing/FAIR-Tests/badge.svg?branch=maain)](https://coveralls.io/github/FAIRsharing/FAIR-Tests?branch=main)


## About

This is a simple Sinatra application which provies a REST API (only, no GUI) for running
FAIR tests.

See also: https://champion.fairsharing.org

## Structure

* fair_tests.rb - the main application file. Run with `rackup`.
* lib/ - contains the FAIR tests, one file per test.
* test/ - contains unit tests for the application. Run these with `bundle exec rake test`.
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

`cp .env.example .env` and edit the value for your API key. You probably won't need
to change the value for the FAIRsharing API URL unless you're running a local instance 
of FAIRsharing.

Run the application with `rerun 'rackup'`.

### Development

Normal Rails tools are not available, so irb could be used during development work. Example:

```irb
bundle exec irb
> require_relative 'lib/test_utils'
> include TestUtils
> get_doi_metadata('https://doi.org/10.25504/FAIRsharing.7g1bzj')
```

### Creating FAIR tests

1. Create a new test file in lib/fair_tests to contain the test logic. This file should be named after the
abbreviation for the FAIR test. For example, ft_f1_m_idgloballyunique.rb. Existing files may be used as 
a template.
2. Create a unit test file in test/. Name this file after the test, but adding _test at the end.
For example, ft_f1_m_idgloballyunique_test.rb.
3. Create a directory in public/test_descriptions/ named after the test (see 1 and 2). Create a single
file in this directory called "api", which should contain the OpenAPI 3.0.0 specification for the test (see 
existing examples).
4. Check that the test works using IRB, and that the unit tests all pass, and create a PR.
5. ...
6. Profit!

### Unit Tests

These can be run with `bundle exec rake test`.

## Deployment


Probably a Systemd service for fair_tests.rb, with an Nginx proxy (TODO).
