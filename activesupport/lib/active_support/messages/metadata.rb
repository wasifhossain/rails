# frozen_string_literal: true
require "time"

module ActiveSupport
  module Messages #:nodoc:
    class Metadata #:nodoc:
      def initialize(expires_at, purpose)
        @expires_at, @purpose = expires_at, purpose.to_s
      end

      class << self
        def wrap(message, expires_at: nil, expires_in: nil, purpose: nil)
          if expires_at || expires_in || purpose
            { "value" => message, "_rails" => { "exp" => pick_expiry(expires_at, expires_in), "pur" => purpose } }
          else
            message
          end
        end

        def verify(message, purpose)
          metadata = extract_metadata(message)

          if metadata.nil?
            message if purpose.nil?
          elsif metadata.match?(purpose) && metadata.fresh?
            message["value"]
          end
        end

        private
          def pick_expiry(expires_at, expires_in)
            if expires_at
              expires_at.utc.iso8601(3)
            elsif expires_in
              Time.now.utc.advance(seconds: expires_in).iso8601(3)
            end
          end

          def extract_metadata(message)
            if message.is_a?(Hash) && message.key?("_rails")
              new(message["_rails"]["exp"], message["_rails"]["pur"])
            end
          end
      end

      def match?(purpose)
        @purpose == purpose.to_s
      end

      def fresh?
        @expires_at.nil? || Time.now.utc < Time.iso8601(@expires_at)
      end
    end
  end
end
