# Consul::Client

Thin Ruby Client around Consul REST API

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'consul-ruby-client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install consul-ruby-client

## Usage

To use the client you have to require the root library

```
# Add the dependencies
require 'consul/client'

# Import that namespace
include Consul::Client
```

### Key Value Store

```
kvs = KeyValue.new
kvs.put('cat','dog')
kvs.get('cat')

```

### Agent

```
# Register a service named 'my_service'
Consul::Client::Agent.new.register(Agent::Service.for_name('my_service'))
```

### Catalog

TODO

### Sessions

TODO

### Status

TODO

## TODO

* Tests,
Currently all test were done throught building and installing the ruby client
and verifying through REPL.  That is not the long term solution.  We are looking
at integrating Consul into the rspec test itself.
However a solid short term win will be completing rspec tests with set fixtures.

* Implement more advance locking mechanisms
* Complete the Agent API self, join, and force-leave
* ACL API
* Events

## Contributing

1. Fork it ( https://github.com/[my-github-username]/consul-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
