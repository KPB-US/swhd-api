require 'swhd_api/version'
require 'swhd_api/exceptions'
require 'typhoeus'
require 'json'

module SwhdApi
  class Manager
    attr_reader :session_id
    attr_reader :url

    def initialize(url = nil, options = {})
      raise SwhdApi::MissingUrl if url.nil? || url.empty?
      # TODO strip trailing slash if any
      @url = url
      @options = options
    end

    def connect(credentials = {})
      if credentials.has_key?(:apikey)
        # HACK for now, remove once they get the sessionKey working as documented
        @session_id = credentials[:apikey]
        return

      elsif credentials.has_key?(:username) && credentials.has_key?(:password)
        # use username and password
        #@session_id = "2"
      elsif credentials.has_key?(:techkey)
        # use tech's key
        #@session_id = "3"
      else
        raise MissingCredentials.new(":apikey or :techkey or :username and :password")
      end

      results = self.request("Session", :get, credentials) #{ "apiKey" => credentials[:apikey] })
      @session_id = results["sessionKey"]
     
    end

    def request(resource, method, params = {}, body = {})
      raise NoSession if @session_id.nil? && resource != "Session"
      raise MissingResource if resource.nil? || resource.empty?
      
      endpoint = "#{@url}/#{resource}"
      # TODO log a call to solarwinds and find out why no one can do this (other users on their forums)
      # HACK for now, use apikey instead of session key
      params["apiKey"] = @session_id
      payload = @options.dup

      response =
      case method
      when :post
        payload[:body] = body
        Typhoeus::Request.post(endpoint, payload)
      when :get
        payload[:params] = params.reject {|k,v| v.nil?}
        Typhoeus::Request.get(endpoint, payload)
      when :put
        payload[:body] = body
        Typhoeus::Request.put(endpoint, payload)
      when :delete
        payload[:params] = params.reject {|k,v| v.nil?}
        Typhoeus::Request.delete(endpoint, payload)
      end

      if response.timed_out?
        raise TimedOut.new(response.body)
      elsif response.code == 0 
        raise NoResponse.new(response.body)
      elsif response.return_code == :partial_file
        raise PartialFile.new(response.body)
      elsif !response.success?
        if response.code > 0
          raise RequestFailed.new("Response Code: #{response.code}\nReturn Code: #{response.return_code} - #{response.return_message}\n#{response.body}")
        else
          begin
            error_messages = JSON.parse(response.body)['error_message']
          rescue
            response_code_desc = response.headers.partition("\r\n")[0].sub(/^\S+/, '') rescue nil
            raise RequestFailed.new("Unknown error #{response_code_desc}")
          else
            raise RequestFailed.new(error_messages)
          end
        end
      end
puts " --------------------------------------- "
puts response.body
puts " --------------------------------------- "
      JSON.parse(response.body)
    end

  end
end