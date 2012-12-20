# Updatamator

Updatamator automates keeping track of available

## Installation

We test installation

## CSS

CSS is generated using SASS which leverages zurb foundation. Modify the CSS by working in /css/sass and compiling with compass via bundler.

    cd css/sass
    bundle install
    bundle exec compass compile

## Testing

Unit testing is done with mocha and integration/frontend testing will be done with casper.js.

You may run the unit tests with the following code (and may add `-w test` if you want the tests to watch a directory and rerun themselves on file change:

  node_modules/.bin/mocha --compilers coffee:coffee-script
