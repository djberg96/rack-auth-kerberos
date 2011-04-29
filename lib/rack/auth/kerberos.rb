require 'krb5_auth'

# The Rack module serves as a namespace only.
module Rack

  # The Auth module serves as a namespace only.
  module Auth

    # The Kerberos class encapsulates kerberos authentication handling.
    class Kerberos
      # The version of the rack-auth-kerberos library.
      VERSION = '0.3.0'

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
        @kerberos = nil
        @app = app
        @user_field = user_field
        @password_field = password_field
        @realm = realm
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
        @kerberos = Kerberos::Krb5.new
        @realm ||= @kerberos.get_default_realm

        @log = "Entering Rack::Auth::Kerberos"
        request = Rack::Request.new(env)

        user = request.params[@user_field]
        password = request.params[@password_field]

        log "Kerberos user: #{user}, password length: #{password.nil? ? 'nil' : password.size}"

        # Only authenticate user if both the username and password fields are present
        unless user && password
          return @app.call(env)
        end

        # Automatically append the realm if not already present
        user_with_realm = user.dup
        user_with_realm += "@#{@realm}" unless user.include?('@')
        log "Kerberos user_with_realm: #{user_with_realm}"

        # Do not authenticate if either one of these is set
        if env['AUTH_USER'] || env['AUTH_FAIL']
          return @app.call(env)
        end

        begin
          @kerberos.get_init_creds_password(user_with_realm, password)
        rescue Kerberos::Krb5::Exception => err
          case err.message
            when /client not found/i
              msg = "Invalid userid '#{user}'"
            when /integrity check failed/i
              msg = "Invalid password for '#{user}'"
            else
              log "Kerberos::Krb5::Exception: #{err.message}"
              msg = "Error attempting to validate userid and password"
          end

          env.delete('AUTH_USER')
          env['AUTH_FAIL'] = msg
        rescue => err
          env.delete('AUTH_USER')
          log "Kerberos Unexpected Error: #{err.message}"
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

        log "Kerberos sign in results: AUTH_TYPE_USER=#{env['AUTH_TYPE_USER']}, AUTH_FAIL=#{env['AUTH_FAIL']}"
        env['AUTH_LOG'] = @log
        @app.call(env)
      end

      # Append a +msg+ to a @log string that can be used for logging & debugging.
      #
      def log(msg)
        @log << "\n    #{msg}"
      end
    end
  end
end
