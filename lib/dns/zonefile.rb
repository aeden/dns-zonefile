module DNS
  class Zonefile
    VERSION = "0.0.1"

    attr_reader :origin, :soa

    class << self
      def parse(zone_string)
        new
      end
    end
  end
end