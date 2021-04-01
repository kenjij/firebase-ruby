require 'firebase-ruby/neko-http'


module Firebase
  class Database
    FIREBASE_URL_TEMPLATE = 'https://%s.firebaseio.com/'

    attr_accessor :auth, :print, :shallow

    def initialize()
    end

    def set_auth_with_key(json: nil, path: nil)
      @auth = Auth.new(json: json, path: path)
    end

    def project_id=(id)
      @project_id = id
    end

    def project_id
      return @project_id if @project_id
      return auth.project_id if auth
      return nil
    end

    def get(path)
      return operate(__method__, path)
    end

    def put(path, data)
      return operate(__method__, path, data)
    end

    def patch(path, data)
      return operate(__method__, path, data)
    end

    def post(path, data)
      return operate(__method__, path, data)
    end

    def delete(path)
      return operate(__method__, path)
    end

    private

    def operate(method, path, data = nil)
      case method
      when :get, :delete
        res_data = http.public_send(method, path: format_path(path))
      when :put, :patch, :post
        data = JSON.fast_generate(data) if data.class == Hash
        res_data = http.public_send(method, path: format_path(path), body: data)
      end
      return handle_response_data(res_data)
    end

    def http
      unless @http
        url = FIREBASE_URL_TEMPLATE % project_id
        @http = Neko::HTTP.new(url, {'Content-Type' => 'application/json'})
      end
      @http.headers['Authorization'] = "Bearer #{auth.valid_token}"
      return @http
    end

    def format_path(path)
      path = '/' + path unless path.start_with?('/')
      return path + '.json'
    end

    def handle_response_data(data)
      if data[:code] != 200
        Firebase.logger.error("HTTP response error: #{data[:code]}\n#{data[:message]}")
        return nil
      end
      return JSON.parse(data[:body], {symbolize_names: true})
    end
  end
end
