require 'net/http'
require 'uri'
require 'json'

class API

  class << self

    def get(base, query)
      base = URI.parse(base)
      base.query = query
      response = Net::HTTP.get_response(base)
      respond(response.code.to_i, JSON.parse(response.body))
    rescue Exception => e
      respond(500, e)
    end

    def respond(status, payload)
      if status == 500
        { "status" => 500, "error" => "Exception: #{payload}" }
      else
        { "status" => 200 }.merge payload
      end
    end
  end
end
