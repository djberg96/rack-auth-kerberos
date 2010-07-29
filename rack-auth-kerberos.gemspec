require 'rubygems'

Gem::Specification.new do |gem|
  gem.name      = 'rack-auth-kerberos'
  gem.version   = '0.2.5'
  gem.authors   = ["Daniel Berger", "Charlie O'Keefe", "Marty Haught"]
  gem.email     = 'dberger@globe.gov'
  gem.homepage  = 'http://www.github.com/rack-kerberos'
  gem.summary   = 'A Rack library that authenticates people using Kerberos'
  gem.test_file = 'test/test_rack_auth_kerberos.rb'
  gem.files     = Dir['**/*'].delete_if{ |item| item.include?('git') } 

  gem.extra_rdoc_files = ['CHANGES', 'README', 'MANIFEST']

  gem.add_dependency('rack', '>= 1.0.0')
  gem.add_dependency('djberg96-krb5-auth', '>= 0.8.5')
  
  gem.description = <<-EOF
    The rack-kerberos library provides a Rack middleware interface for
    authenticating users against a Kerberos server.
  EOF
end
