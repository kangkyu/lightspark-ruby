# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "lightspark"

require "minitest/autorun"

Dir['./test/support/**/*.rb'].each { |f| require f }
