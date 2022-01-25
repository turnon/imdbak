require "test_helper"

class ImdbakTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Imdbak::VERSION
  end
end
