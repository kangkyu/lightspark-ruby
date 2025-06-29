# Lightspark

Welcome to the new gem! This gem is under development for using Lightspark API with Ruby.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add ls
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install ls
```

## Usage

Go to https://app.lightspark.com/api-config and get values for

- `LIGHTSPARK_API_TOKEN_CLIENT_ID`
- `LIGHTSPARK_API_TOKEN_CLIENT_SECRET`

```rb
client = Lightspark::GraphqlClient.new
client.current_account
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kangkyu/lightspark-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/kangkyu/lightspark-ruby/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Lightspark project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/kangkyu/lightspark-ruby/blob/master/CODE_OF_CONDUCT.md).
