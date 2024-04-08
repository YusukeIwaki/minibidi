require 'minitest/autorun'
require 'minibidi'

class MinibidiTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Minibidi::VERSION
  end
end
