# Build

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/build`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'build'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install build

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

### Installing the gem locally

Run `bundle exec rake install`.

### Publishing to RubyGems

1. Update the version number in `version.rb`
1. Download the api key for the sysadmin@socrata.com: `curl -u "sysadmin@socrata.com:[password in LastPass under\
   rubygems.org]" https://rubygems.org/api/v1/api_key.json`
1. Place api key in ~/.gem/credentials. File should look like:
    ---
    :rubygems_api_key: [api key you downloaded]
1. At root of this repo and when it is clean with no unchecked in changes, run `bundle exec rake release`

## Contributing

1. Fork it ( https://github.com/[my-github-username]/build/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
