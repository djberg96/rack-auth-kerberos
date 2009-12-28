require 'krb5_auth'

module Rack
  module Auth
    class Kerberos
      # The version of the rack-auth-kerberos library.
      VERSION = '0.2.0'

      # Creates a new Rack::Kerberos object. The +user_field+ and +password_field+
      # are the params looked for in the call method. The defaults are 'username'
      # and 'password', respectively.
      #
      # If the optional +realm+ parameter is supplied it will override the
      # default realm specified in your krb5.conf file.
      #
      # The realm is automatically appended to the username if not already
      # present. This makes it easier for application developers, i.e. they can
      # supply a username with or without a realm and it will Just Work (TM).
      #
      def initialize(app, user_field = 'username', password_field = 'password', realm = nil)
        @app = app
        @user_field = user_field
        @password_field = password_field
        @kerberos = Krb5Auth::Krb5.new

        if realm
          @realm = realm
        else
          @realm = @kerberos.get_default_realm
        end
      end

      # The call method we've defined first checks to see if the AUTH_USER
      # environment variable is set. If it is, we assume that the user has
      # already been authenticated and move on.
      #
      # If AUTH_USER is not set, and AUTH_FAIL is not set, we then attempt
      # to authenticate the user against the Kerberos server. If successful
      # then AUTH_USER is set to the username.
      #
      # If unsuccessful then AUTH_USER is set to nil and AUTH_FAIL is
      # set to an appropriate error message.
      #
      # It is then up to the application to check for the presence of AUTH_USER
      # and/or AUTH_FAIL and act as necessary.
      #
      # Several other request environment variables are set on success:
      #
      # AUTH_TYPE               => "Kerberos Password"
      # AUTH_TYPE_USER          => user + realm
      # AUTH_TYPE_THIS_REQUEST  => "Kerberos Password"
      # AUTH_DATETIME           => Time.now.utc
      #
      def call(env)
        request = Rack::Request.new(env)

        user = request.params[@user_field]
        password = request.params[@password_field]

        # Only authenticate user if both the username and password fields are present
        unless user && password
          return @app.call(env)
        end

        # Automatically append the realm if not already present
        user_with_realm = user.dup
        user_with_realm += "@#{@realm}" unless user.include?('@')

        # Do not authenticate if either one of these is set
        if env['AUTH_USER'] || env['AUTH_FAIL']
          return @app.call(env)
        end

        begin
          @kerberos.get_init_creds_password(user_with_realm, password)
        rescue Krb5Auth::Krb5::Exception => err
          case err.message
            when /client not found/i
              msg = "Invalid userid '#{user}'"
            when /integrity check failed/i
              msg = "Invalid password for '#{user}'"
            else
              msg = "Error attempting to validate userid and password"
          end

          env.delete('AUTH_USER')
          env['AUTH_FAIL'] = msg
        rescue => err
          env.delete('AUTH_USER')
          env['AUTH_FAIL'] = "Unexpected failure during Kerberos authentication"
        else
          env.delete('AUTH_FAIL')

          env['AUTH_USER'] = user
          env['AUTH_TYPE'] = "Kerberos Password"
          env['AUTH_TYPE_USER'] = user_with_realm
          env['AUTH_TYPE_THIS_REQUEST'] = "Kerberos Password"
          env['AUTH_DATETIME'] = Time.now.utc
        ensure
          @kerberos.close
        end

        @app.call(env)
      end
    end
  end
end
