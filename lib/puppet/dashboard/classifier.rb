require 'puppet'
require 'puppet/network/http_pool'
module Puppet::Dashboard
  class Classifier
    def self.connection(options)
      @connection ||= Puppet::Dashboard::Classifier.new(options, false)
    end

    def initialize(options, use_ssl=false)
      @http_connection = Puppet::Network::HttpPool.http_instance(options[:enc_server], options[:enc_port])
      # Workaround for the fact that Dashboard is typically insecure.
      @http_connection.use_ssl = use_ssl
      @headers = { 'Content-Type' => 'application/json' }
    end

    # list expects a return of 200
    def list(type, action)
      response = @http_connection.get("/#{type}.json", @headers )
      nodes = handle_json_response(response, action)
    end

    def create(type, action, data)
      response = @http_connection.post("/#{type}.json", data.to_pson, @headers)
      handle_json_response(response, action, '201')
    end

    def handle_json_response(response, action, expected_code='200')
      if response.code == expected_code
        Puppet.notice "#{action} ... Done"
        PSON.parse response.body
      else
        # I should probably raise an exception!
        Puppet.warning "#{action} ... Failed"
        Puppet.info("Body: #{response.body}")
        Puppet.warning "Server responded with a #{response.code} status"
        raise Puppet::Error, "Could not: #{action}, got #{response.code} expected #{expected_code}"
      end
    end
  end
end
