require 'test/unit'
require 'rack/auth/kerberos'

class TC_Rack_Auth_Kerberos < Test::Unit::TestCase
  def setup
    @app  = 1 # Placeholder
    @env  = 1 # Placeholder
    @rack = Rack::Auth::Kerberos.new(@app)
  end

  def test_constructor_basic
    assert_nothing_raised{ Rack::Auth::Kerberos.new(@app) }
  end

  def test_version
    assert_equal('0.2.5', Rack::Auth::Kerberos::VERSION)
  end

  def teardown
    @rack = nil
  end
end
