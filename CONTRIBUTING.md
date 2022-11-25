# Contributing to dns-zonefile

## Getting started

Clone the repository and move into it:

```
$ git clone git@github.com:craigw/dns-zonefile.git
$ cd dns-zonefile
```

Install the dependencies using [Bundler](http://bundler.io/):

```
$ bundle
```

[Run the test suite](#testing) to check everything works as expected.


## Testing

To run the test suite:

```
$ rake
```


## Tests

Submit unit tests for your changes. You can test your changes on your machine by [running the test suite](#testing).

## Publishing

Once a PR is merged into master, bump the version in `lib/dns/zonefile/version.rb` and commit that change. Next, add a new tag with that version number and push the tag to GitHub. Finally, if you are a maintainer with access rights for rubygems.org, run `gem build dns-zonefile.gemspec` followed by `gem push dns-zonefile-x.x.x.gem` where x.x.x is the version number you just set.
