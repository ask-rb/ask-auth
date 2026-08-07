# frozen_string_literal: true

require "net/http"
require "uri"

module Ask
  module Auth
    module OAuth
      # Minimal form-encoded POST for token endpoints — stdlib only, so
      # ask-auth stays dependency-free. Swappable in tests.
      module HTTP
        OPEN_TIMEOUT = 10
        READ_TIMEOUT = 30

        def self.post_form(url, params, headers: {})
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.open_timeout = OPEN_TIMEOUT
          http.read_timeout = READ_TIMEOUT
          http.use_ssl = uri.scheme == "https"
          req = Net::HTTP::Post.new(uri)
          req.set_form_data(params)
          headers.each { |k, v| req[k] = v }
          res = http.request(req)
          [res.code.to_i, res.body.to_s]
        end
      end
    end
  end
end
