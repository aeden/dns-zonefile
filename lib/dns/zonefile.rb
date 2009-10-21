require 'dns/zonefile_parser'

module DNS
  class Zonefile
    VERSION = "0.0.1"

    attr_reader :origin, :soa

    class << self
      def parse(zone_string)
        parser = DNS::ZonefileParser.new
        parser.parse(zone_string)
      end
    end
  end
end