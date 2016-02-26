# SwhdApi

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'swhd_api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install swhd_api

## Usage

```ruby
require 'swhd_api'
m = SwhdApi::Manager.new(url, options)
m.connect(credentials)
m.request("Clients", :get).count 
m.fetch("Clients").count
```

The _url_ is the api service url such as `https://helpdesk/helpdesk/WebObjects/Helpdesk.woa/ra`
and _options_, if specified, is a hash that is passed to Typhoeus, and if you are using a self-signed
SSL certificate, it may need to contain `{ ssl_verifypeer: false, ssl_verifyhost: 0 }`.  There's
also the `{ verbose: true }` option, if you are debugging with irb.

The _credentials_ hash includes one of the following
`{ apikey: value }`
`{ techkey: value }`
`{ username: value, password: value }`
and is used to obtain a session for subsequent calls.

** there are problems with their session api, so for now we have to pass the apikey: value in the credentials so they
get stored in the code and passed along instead of the sessionKey.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/swhd_api.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

