# Rongyun

* Rongyun Related Operation

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rongyun'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rongyun

## Usage

```ruby
client = Rongyun::Client.new
client.user_get_token(user_id, name, portrait_uri)
...
```

## Contributing

1. Fork it ( https://github.com/yangxing-star/rongyun/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request