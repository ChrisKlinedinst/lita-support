require 'uri'

class UrlParser

  class << self
    TYPES = %w(space dashboard instrument).freeze

    def parse(url)
      errors = []
      type, id = URI.parse(url).path
                  .sub(/\/(s\/)?/, '') # removes leading '/' and spaces prefix '/s/'
                  .split('/')

      type.sub!(/s$/, '') if type      # plural to singular

      unless TYPES.include?(type)
        errors.push "Resource is not a #{TYPES.join(', ')}"
      end

      unless id
        errors.push "Please include the id for the #{TYPES.join(', ')}"
      end

      {
        type: "#{type}_id",
        id: id,
        errors: errors
      }
    end
  end
end
