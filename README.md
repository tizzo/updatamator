# Updatamator

Updatamator automates keeping track of available packages and issue commands to update them via the package manager on a given system.

## Installation

Currently only tested with debian and apt is the only system for which a script is provided. The script in bin/apticronjson.sh is a fork of apticron to generate valid json on stdout rather than sending emails. Currently it's up to you to post the information to your updatamator server. Here's an example of how to do that with our test data.

    curl -H "Content-Type: application/json" -d @test/json-samples/json-sample-1.json -X POST localhost:3005/package-updates

## CSS

CSS is generated using SASS which leverages zurb foundation. Modify the CSS by working in /css/sass and compiling with compass via bundler.

    cd css/sass
    bundle install
    bundle exec compass compile

## Testing

Unit testing is done with mocha and integration/frontend testing will be done with casper.js.

You may run the unit tests with the following code (and may add `-w test` if you want the tests to watch a directory and rerun themselves on file change:

  node_modules/.bin/mocha --compilers coffee:coffee-script
