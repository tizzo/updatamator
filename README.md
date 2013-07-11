# Updatamator

Updatamator automates keeping track of available packages updates across your set of servers and issuing commands to update them via the appropriate package manager on a given system.

Each server is expected to call home by posting JSON to a configurable port. A [reporter script](https://github.com/tizzo/updatamator/blob/master/bin/updatamator-reporter.debian.sh) based on apticron for use with Debian is provided in the bin folder and examples of the JSON expected used by the unit tests can be found in the [tests/json-samples](https://github.com/tizzo/updatamator/tree/master/test/json-samples) folder. Providing a script for yum based systems is planned, patches welcome.

## Installation

### Installing Updatamator

  1. Clone the updatamator repository, copy `config/example.config.json` to `config/config.json` and edit to taste.
  2. Run `npm start`.
  3. Manage it with [forever](https://github.com/nodejitsu/forever), add it to [supervisord](http://supervisord.org/), write yourself an [upstart](http://howtonode.org/deploying-node-upstart-monit) or init script, or however you manage processes on your system.

### Installing the Updatamator Reporter

Setup a cron job to check for updates and report the findings home.

#### Debian and Ubuntu

Currently only tested with Ubuntu and apt is the only system for which a script is provided. The script in bin/updatamator-reporter.debian.sh is a fork of apticron to generate and post json rather than sending emails.

The reporter reads configuration from a `/etc/updatamator/updatamator.conf` file which should set the environment variables for `REPORT_HOST` (the hostname of the updatamator isntance), `REPORT_PATH` (this should usually be `package-updates` but is configurable in case you are doing something clever with a reverse proxy, etc), and `SECRET` (which is essentially an API key that must match the one on the updatamator instance).

#### Fedora and CentOS

Coming soon...

## Contributing

Use github issues, fork this repository, and submit pull requests.

### CSS

CSS is generated using SASS which leverages zurb foundation. Modify the CSS by working in /css/sass and compiling with compass via bundler.

    cd css/sass
    bundle install
    bundle exec compass compile

### Tests

Unit testing is done with mocha and integration/frontend may eventually be done with casper.js.

You may run the unit tests with `npm test` or you can run `./node_modules/mocha/bin/mocha --compilers coffee:coffee-script` directly if you want to specify more options (particularly useful is `-w .` to watch the repository and rerun tests on file changes).

If you want to simulate a report coming in on a test instance you can do that by sending some of the example JSON used for testing with CURL using a command like the following:

    curl -H "Content-Type: application/json" -d @test/json-samples/json-sample-1.json -X POST localhost:3005/package-updates

Or you can use the included script to submit all of the json examples in one go:

    sh test/submit-test-json.sh


## TODO:

While this project has already proved useful to me, there's lots to do to make this a mature project.

  - Build an installable package
  - Provide sample init/upstart scripts
  - Reporting
    - Provide a route that can be used by nagios (sensu, icinga, shinken, etc) to track metrics and alert on number of servers, age of updates, etc.
    - Configurable direct reporting plugins to send emails, post to chat, etc. when updates are available
  - Track whether a package is a security update
  - Support CentOS
  - Perhaps provide some sort of clustering to scale past the limits imposed by a single process, though currently no environment where updatamator is running is anywhere near the limit
