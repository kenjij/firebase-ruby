require 'net/http'
require 'openssl'


module Firebase

  class HTTP

    METHOD_HTTP_CLASS = {
      get: Net::HTTP::Get,
      put: Net::HTTP::Put,
      patch: Net::HTTP::Patch,
      post: Net::HTTP::Post,
      delete: Net::HTTP::Delete
    }

    def self.get(url, params)
      h = HTTP.new(url)
      data = h.get(params: params)
      h.close
      return data
    end

    def self.post_form(url, params)
      h = HTTP.new(url)
      data = h.post(params: params)
      h.close
      return data
    end

    attr_reader :init_uri, :http
    attr_accessor :headers

    def initialize(url, hdrs = nil)
      @init_uri = URI(url)
      raise ArgumentError, 'Invalid URL' unless @init_uri.class <= URI::HTTP
      @http = Net::HTTP.new(init_uri.host, init_uri.port)
      http.use_ssl = init_uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      self.headers = hdrs
    end

    def get(path: nil, params: nil, query: nil)
      return operate(__method__, path: path, params: params, query: query)
    end

    def post(path: nil, params: nil, body: nil, query: nil)
      return operate(__method__, path: path, params: params, body: body, query: query)
    end

    def put(path: nil, params: nil, body: nil, query: nil)
      return operate(__method__, path: path, params: params, body: body, query: query)
    end

    def patch(path: nil, params: nil, body: nil, query: nil)
      return operate(__method__, path: path, params: params, body: body, query: query)
    end

    def delete(path: nil, params: nil, query: nil)
      return operate(__method__, path: path, params: params, query: query)
    end

    def close
      http.finish if http.started?
    end

    private

    def operate(method, path: nil, params: nil, body: nil, query: nil)
      uri = uri_with_path(path)
      case method
      when :get, :delete
        if params
          query = URI.encode_www_form(params)
          Firebase.logger.info('Created urlencoded query from params')
        end
        uri.query = query
        req = METHOD_HTTP_CLASS[method].new(uri)
      when :put, :patch, :post
        uri.query = query if query
        req = METHOD_HTTP_CLASS[method].new(uri)
        if params
          req.form_data = params
          Firebase.logger.info('Created form data from params')
        elsif body
          req.body = body
        end
      else
        return nil
      end
      data = send(req)
      data = redirect(method, uri, params: params, body: body, query: query) if data.class <= URI::HTTP
      return data
    end

    def uri_with_path(path)
      uri = init_uri.clone
      uri.path = path unless path.nil?
      return uri
    end

    def send(req)
      inject_headers_to(req)
      unless http.started?
        Firebase.logger.info('HTTP session not started; starting now')
        http.start
        Firebase.logger.debug("Opened connection to #{http.address}:#{http.port}")
      end
      Firebase.logger.debug("Sending HTTP #{req.method} request to #{req.path}")
      Firebase.logger.debug("Body size: #{req.body.length}") if req.request_body_permitted?
      res = http.request(req)
      return handle_response(res)
    end

    def inject_headers_to(req)
      return if headers.nil?
      headers.each do |k, v|
        req[k] = v
      end
      Firebase.logger.info('Header injected into HTTP request header')
    end

    def handle_response(res)
      if res.connection_close?
        Firebase.logger.info('HTTP response header says connection close; closing session now')
        close
      end
      case res
      when Net::HTTPRedirection
        Firebase.logger.info('HTTP response was a redirect')
        data = URI(res['Location'])
        if data.class == URI::Generic
          data = uri_with_path(res['Location'])
          Firebase.logger.debug("Full URI object built for local redirect with path: #{data.path}")
        end
      # when Net::HTTPSuccess
      # when Net::HTTPClientError
      # when Net::HTTPServerError
      else
        data = {
          code: res.code.to_i,
          headers: res.to_hash,
          body: res.body,
          message: res.msg
        }
      end
      return data
    end

    def redirect(method, uri, params: nil, body: nil, query: nil)
      if uri.host == init_uri.host && uri.port == init_uri.port
        Firebase.logger.info("Local #{method.upcase} redirect, reusing HTTP session")
        new_http = http
      else
        Firebase.logger.info("External #{method.upcase} redirect, spawning new HTTP object")
        new_http = HTTP.new("#{uri.scheme}://#{uri.host}#{uri.path}", headers)
      end
      case method
      when :get, :delete
        data = operate(method, uri, params: params, query: query)
      when :put, :patch, :post
        data = new_http.public_send(method, uri, params: params, body: body, query: query)
      else
        data = nil
      end
      return data
    end

  end

end
