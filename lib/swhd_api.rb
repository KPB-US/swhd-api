require 'swhd_api/version'
require 'swhd_api/exceptions'
require 'typhoeus'
require 'json'

module SwhdApi
  # main api helper class
  class Manager
    attr_reader :session_id
    attr_reader :url
    attr_accessor :logger

    def initialize(url = nil, options = {})
      raise SwhdApi::MissingUrl if url.nil? || url.empty?
      # TODO: strip trailing slash if any
      @url = url
      @options = options
    end

    def connect(credentials = {})
      if credentials.key?(:apikey)
        # HACK: remove once SolarWinds get the sessionKey working as documented
        @session_id = credentials[:apikey]
        return

      elsif credentials.key?(:username) && credentials.key?(:password)
        # use username and password
        # @session_id = "2"
      elsif credentials.key?(:techkey)
        # use tech's key
        # @session_id = "3"
      else
        raise MissingCredentials, ':apikey or :techkey or :username and :password'
      end

      results = request('Session', :get, credentials) # { "apiKey" => credentials[:apikey] })
      @session_id = results['sessionKey']
    end

    def request(resource, method, params = {}, body = {})
      raise NoSession if @session_id.nil? && resource != 'Session'
      raise MissingResource if resource.nil? || resource.empty?

      endpoint = "#{@url}/#{resource}"
      # TODO: log a call to solarwinds and find out why no one can do this (other users on their forums)
      # HACK: for now, use apikey instead of session key
      params['apiKey'] = @session_id
      payload = @options.dup
      payload[:params] = params.reject { |_k, v| v.nil? }

      response =
        case method
        when :post
          payload[:body] = body.to_json
          Typhoeus::Request.post(endpoint, payload)
        when :get
          Typhoeus::Request.get(endpoint, payload)
        when :put
          payload[:body] = body.to_json
          Typhoeus::Request.put(endpoint, payload)
        when :delete
          Typhoeus::Request.delete(endpoint, payload)
        end

      if response.timed_out?
        raise TimedOut, response.body
      elsif response.code == 0
        raise NoResponse, response.body
      elsif response.return_code == :partial_file
        raise PartialFile, response.body
      elsif !response.success?
        raise AuthenticationFailure, response.return_message if response.code == 401
        raise RequestFailed, "Response Code: #{response.code}\n
          Return Code: #{response.return_code} - #{response.return_message}\n
          #{response.body}"
      end

      @logger.debug response.body unless @logger.nil?

      JSON.parse(response.body)
    end

    # fetch all pages of results
    def fetch(resource, params = {})
      method = :get
      page = 1

      params[:page] = page
      partial = request(resource, method, params)
      while partial.is_a?(Array) && !partial.empty?
        results ||= []
        results += partial
        page += 1
        params[:page] = page
        partial = request(resource, method, params)
      end

      results = partial unless partial.nil? || partial.empty?
      results
    end
  end
end
