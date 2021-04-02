require 'jwt'
require 'firebase-ruby/neko-http'


module Firebase
  class Auth
    GOOGLE_JWT_SCOPE = 'https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email'
    GOOGLE_JWT_AUD = 'https://oauth2.googleapis.com/token'
    GOOGLE_ALGORITHM = 'RS256'
    GOOGLE_GRANT_TYPE = 'urn:ietf:params:oauth:grant-type:jwt-bearer'
    GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token'

    attr_reader :project_id
    attr_reader :client_email
    attr_reader :token_uri
    attr_reader :access_token
    attr_reader :expires

    # Creates Firebase OAuth based auth object; one argument must be specified
    def initialize(json: nil, path: nil)
      if json
        load_privatekeyjson(json)
      elsif path
        load_privatekeyfile(path)
      end
    end

    # Return a valid access token; it will retrieve a new token if necessary
    def valid_token
      return access_token if access_token && !expiring?
      return access_token if request_access_token
      raise 'No valid access token.'
    end

    # If token is expiring within a minute
    def expiring?
      return true if expires - Time.now < 60
      return false
    end

    # If token has already expired
    def expired?
      return true if expires - Time.now <= 0
      return false
    end

    private

    # @param json [String] JSON with private key
    def load_privatekeyjson(json)
      raise ArgumentError, 'private key JSON missing' unless json
      cred = JSON.parse(json, {symbolize_names: true})
      @private_key = cred[:private_key]
      @project_id = cred[:project_id]
      @client_email = cred[:client_email]
      @token_uri = cred[:token_uri]
      @token_uri ||= GOOGLE_TOKEN_URL
      Firebase.logger.info('Private key loaded from JSON')
      s = [:project_id, :client_email].map{ |x| "#{x}: #{self.public_send(x)}" }
      Firebase.logger.debug("The key contained:\n#{s.join("\n")}")
    end

    # @param path [String] path to JSON file with private key
    def load_privatekeyfile(path)
      raise ArgumentError, 'private key file path missing' unless path
      Firebase.logger.debug("Loading private key file: #{path}")
      load_privatekeyjson(IO.read(path))
    end

    # Request new token from Google
    def request_access_token
      Firebase.logger.info('Requesting access token...')
      Firebase.logger.debug("token_uri: #{token_uri}")
      res = Neko::HTTP.post_form(token_uri, jwt)
      Firebase.logger.debug("HTTP response code: #{res[:code]}")
      if res.class == Hash && res[:code] == 200
        data = JSON.parse(res[:body], {symbolize_names: true})
        @access_token = data[:access_token]
        @expires = Time.now + data[:expires_in]
        Firebase.logger.info('Access token acquired.')
        s = "Token #{@access_token.length} bytes, expires #{@expires}"
        Firebase.logger.debug(s)
        return true
      else
        Firebase.logger.error('Access token request failed.')
        Firebase.logger.debug("HTTP #{res[:code]} #{res[:message]}")
      end
      return false
    end

    # Generate JWT claim
    def jwt
      pkey = OpenSSL::PKey::RSA.new(@private_key)
      now_ts = Time.now.to_i
      payload = {
        iss: client_email,
        scope: GOOGLE_JWT_SCOPE,
        aud: GOOGLE_JWT_AUD,
        iat: now_ts,
        exp: now_ts + 60
      }
      jwt = JWT.encode payload, pkey, GOOGLE_ALGORITHM
      return {grant_type: GOOGLE_GRANT_TYPE, assertion: jwt}
    end
  end
end
