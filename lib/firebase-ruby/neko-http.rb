# NekoHTTP - Pure Ruby HTTP client using net/http
# 
# v.20200629

require 'json'
require 'logger'
require 'net/http'
require 'openssl'

module Neko
  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= NullLogger.new()
  end

  class HTTP
    METHOD_HTTP_CLASS = {
      get: Net::HTTP::Get,
      put: Net::HTTP::Put,
      patch: Net::HTTP::Patch,
      post: Net::HTTP::Post,
      delete: Net::HTTP::Delete
    }

    # Simple GET request
    # @param url [String] full URL string
    # @param params [Array, Hash] it will be converted to URL encoded query
    # @param hdrs [Hash] HTTP headers
    # @return [Hash] contains: :code, :headers, :body, :message
    def self.get(url, params, hdrs = nil)
      h = HTTP.new(url, hdrs)
      data = h.get(params: params)
      h.close
      return data
    end

    # Send POST request with form data URL encoded body
    # @param url [String] full URL string
    # @param params [Array, Hash] it will be converted to URL encoded body
    # @param hdrs [Hash] HTTP headers
    # @return (see #self.get)
    def self.post_form(url, params, hdrs = nil)
      h = HTTP.new(url, hdrs)
      data = h.post(params: params)
      h.close
      return data
    end

    # Send POST request with JSON body
    # It will set the Content-Type to application/json.
    # @param url [String] full URL string
    # @param obj [Array, Hash, String] Array/Hash will be converted to JSON
    # @param hdrs [Hash] HTTP headers
    # @return (see #self.get)
    def self.post_json(url, obj, hdrs = {})
      hdrs['Content-Type'] = 'application/json'
      h = HTTP.new(url, hdrs)
      case obj
      when Array, Hash
        body = JSON.fast_generate(obj)
      when String
        body = obj
      else
        raise ArgumentError, 'Argument is neither Array, Hash, String'
      end
      data = h.post(body: body)
      h.close
      return data
    end

    attr_reader :init_uri, :http
    attr_accessor :logger, :headers

    # Instance constructor for tailored use
    # @param url [String] full URL string
    # @param hdrs [Hash] HTTP headers
    def initialize(url, hdrs = nil)
      @logger = Neko.logger
      @init_uri = URI(url)
      raise ArgumentError, 'Invalid URL' unless @init_uri.class <= URI::HTTP
      @http = Net::HTTP.new(init_uri.host, init_uri.port)
      http.use_ssl = init_uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      @headers = hdrs
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
          logger.info('Created urlencoded query from params')
        end
        uri.query = query if query
        req = METHOD_HTTP_CLASS[method].new(uri)
      when :put, :patch, :post
        uri.query = query if query
        req = METHOD_HTTP_CLASS[method].new(uri)
        if params
          req.form_data = params
          logger.info('Created form data from params')
        elsif body
          req.body = body
        end
      else
        return nil
      end
      if uri.userinfo
        req.basic_auth(uri.user, uri.password)
        logger.info('Created basic auth header from URL')
      end
      data = send(req)
      data = redirect(method, uri: data, body: req.body) if data.class <= URI::HTTP
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
        logger.info('HTTP session not started; starting now')
        http.start
        logger.debug("Opened connection to #{http.address}:#{http.port}")
      end
      logger.debug("Sending HTTP #{req.method} request to #{req.path}")
      logger.debug("Body size: #{req.body.length}") if req.request_body_permitted?
      res = http.request(req)
      return handle_response(res)
    end

    def inject_headers_to(req)
      return if headers.nil?
      headers.each { |k, v| req[k] = v }
      logger.info('Header injected into HTTP request header')
    end

    def handle_response(res)
      if res.connection_close?
        logger.info('HTTP response header says connection close; closing session now')
        close
      end
      case res
      when Net::HTTPRedirection
        logger.info('HTTP response was a redirect')
        data = URI(res['Location'])
        if data.class == URI::Generic
          data = uri_with_path(res['Location'])
          logger.debug("Full URI object built for local redirect with path: #{data.path}")
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

    def redirect(method, uri:, body: nil)
      if uri.host == init_uri.host && uri.port == init_uri.port
        logger.info("Local #{method.upcase} redirect, reusing HTTP session")
        new_http = self
      else
        logger.info("External #{method.upcase} redirect, spawning new HTTP object")
        new_http = HTTP.new("#{uri.scheme}://#{uri.host}#{uri.path}", headers)
      end
      new_http.__send__(:operate, method, path: uri.path, body: body, query: uri.query)
    end
  end

  class NullLogger < Logger
    def initialize(*args)
    end

    def add(*args, &block)
    end
  end
end
