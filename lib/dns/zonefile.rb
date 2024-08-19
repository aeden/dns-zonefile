require "dns/zonefile/version"
require "treetop"
Treetop.load File.expand_path("../zonefile", __FILE__)

module DNS
  module Zonefile
    class << self
      def parse(zone_string)
        parser = ZonefileParser.new
        result = parser.parse(zone_string)
        return result if result
        raise ParsingError, parser.failure_reason
      end

      def load(zone_string, alternate_origin = nil)
        Zone.new(parse(zone_string).entries, alternate_origin)
      end
    end

    class ParsingError < RuntimeError; end
    class UnknownRecordType < RuntimeError; end
    class Zone
      attr_reader :origin
      attr_reader :records

      def initialize(entries, alternate_origin = nil)
        alternate_origin ||= "."
        @records = []
        @vars = {"origin" => alternate_origin, :last_host => "."}
        entries.each do |e|
          case e.parse_type
          when :variable
            key = e.name.text_value.downcase
            @vars[key] = case key
            when "ttl"
              e.value.text_value.to_i
            else
              e.value.text_value
            end
          when :soa
            @records << SOA.new(@vars, e)
          when :record
            case e.record_type
            when "A" then @records << A.new(@vars, e)
            when "AAAA" then @records << AAAA.new(@vars, e)
            when "CAA" then @records << CAA.new(@vars, e)
            when "CNAME" then @records << CNAME.new(@vars, e)
            when "MX" then @records << MX.new(@vars, e)
            when "NAPTR" then @records << NAPTR.new(@vars, e)
            when "NS" then @records << NS.new(@vars, e)
            when "PTR" then @records << PTR.new(@vars, e)
            when "SRV" then @records << SRV.new(@vars, e)
            when "SPF" then @records << SPF.new(@vars, e)
            when "SSHFP" then @records << SSHFP.new(@vars, e)
            when "TXT" then @records << TXT.new(@vars, e)
            when "SOA" then
              # No-op
            else
              raise UnknownRecordType, "Unknown record type: #{e.record_type}"
            end
          end
        end
      end

      def soa
        records_of(SOA).first
      end

      def records_of(kl)
        @records.select { |r| r.instance_of? kl }
      end
    end

    class Record
      # assign, with handling for global TTL
      def self.writer_for_ttl(*attribs)
        attribs.each do |attrib|
          define_method "#{attrib}=" do |val|
            instance_variable_set("@#{attrib}", val || @vars["ttl"])
          end
        end
      end

      attr_reader :ttl
      attr_writer :klass
      writer_for_ttl :ttl

      def klass
        @klass = nil if @klass == ""
        @klass ||= "IN"
      end

      attr_accessor :comment

      private

      def qualify_host(host)
        origin = vars["origin"]
        host = vars[:last_host] if /^\s*$/.match?(host)
        host = host.gsub(/@/, origin)
        if /\.$/.match?(host)
          host
        elsif /^\./.match?(origin)
          host + origin
        else
          host + "." + origin
        end
      end
      attr_accessor :vars
    end

    class SOA < Record
      attr_accessor :origin, :nameserver, :responsible_party, :serial, :refresh_time, :retry_time, :expiry_time, :nxttl

      def initialize(vars, zonefile_soa = nil)
        @vars = vars
        if zonefile_soa
          self.origin = qualify_host(zonefile_soa.origin.to_s)
          @vars[:last_host] = origin
          self.ttl = zonefile_soa.ttl.to_i
          self.klass = zonefile_soa.klass.to_s
          self.nameserver = qualify_host(zonefile_soa.ns.to_s)
          self.responsible_party = qualify_host(zonefile_soa.rp.to_s)
          self.serial = zonefile_soa.serial.to_i
          self.refresh_time = zonefile_soa.refresh.to_i
          self.retry_time = zonefile_soa.reretry.to_i
          self.expiry_time = zonefile_soa.expiry.to_i
          self.nxttl = zonefile_soa.nxttl.to_i
        end
      end
    end

    class A < Record
      attr_accessor :host, :address

      def initialize(vars, zonefile_record)
        @vars = vars
        if zonefile_record
          self.host = qualify_host(zonefile_record.host.to_s)
          @vars[:last_host] = host
          self.ttl = zonefile_record.ttl.to_i
          self.klass = zonefile_record.klass.to_s
          self.address = zonefile_record.ip_address.to_s
          self.comment = zonefile_record.comment&.to_s
        end
      end
    end

    class AAAA < A
    end

    class CAA < Record
      attr_accessor :host, :flags, :tag, :value

      def initialize(vars, zonefile_record)
        @vars = vars
        if zonefile_record
          self.host = qualify_host(zonefile_record.host.to_s)
          @vars[:last_host] = host
          self.ttl = zonefile_record.ttl.to_i
          self.klass = zonefile_record.klass.to_s
          self.flags = zonefile_record.flags.to_i
          self.tag = zonefile_record.tag.to_s
          self.value = zonefile_record.value.to_s
          self.comment = zonefile_record.comment&.to_s
        end
      end
    end

    class CNAME < Record
      attr_accessor :host, :domainname

      def initialize(vars, zonefile_record)
        @vars = vars
        if zonefile_record
          self.host = qualify_host(zonefile_record.host.to_s)
          @vars[:last_host] = host
          self.ttl = zonefile_record.ttl.to_i
          self.klass = zonefile_record.klass.to_s
          self.domainname = qualify_host(zonefile_record.target.to_s)
          self.comment = zonefile_record.comment&.to_s
        end
      end

      alias target domainname
      alias alias host
    end

    class MX < Record
      attr_accessor :host, :priority, :domainname

      def initialize(vars, zonefile_record)
        @vars = vars
        if zonefile_record
          self.host = qualify_host(zonefile_record.host.to_s)
          @vars[:last_host] = host
          self.ttl = zonefile_record.ttl.to_i
          self.klass = zonefile_record.klass.to_s
          self.priority = zonefile_record.priority.to_i
          self.domainname = qualify_host(zonefile_record.exchanger.to_s)
          self.comment = zonefile_record.comment&.to_s
        end
      end

      alias exchange domainname
      alias exchanger domainname
    end

    class NAPTR < Record
      attr_accessor :host, :data

      def initialize(vars, zonefile_record)
        @vars = vars
        if zonefile_record
          self.host = qualify_host(zonefile_record.host.to_s)
          @vars[:last_host] = host
          self.ttl = zonefile_record.ttl.to_i
          self.klass = zonefile_record.klass.to_s
          self.data = zonefile_record.data.to_s
          self.comment = zonefile_record.comment&.to_s
        end
      end
    end

    class NS < Record
      attr_accessor :host, :domainname

      def initialize(vars, zonefile_record)
        @vars = vars
        if zonefile_record
          self.host = qualify_host(zonefile_record.host.to_s)
          @vars[:last_host] = host
          self.ttl = zonefile_record.ttl.to_i
          self.klass = zonefile_record.klass.to_s
          self.domainname = qualify_host(zonefile_record.nameserver.to_s)
          self.comment = zonefile_record.comment&.to_s
        end
      end

      alias nameserver domainname
    end

    class PTR < Record
      attr_accessor :host, :domainname

      def initialize(vars, zonefile_record)
        @vars = vars
        if zonefile_record
          self.host = qualify_host(zonefile_record.host.to_s)
          @vars[:last_host] = host
          self.ttl = zonefile_record.ttl.to_i
          self.klass = zonefile_record.klass.to_s
          self.domainname = qualify_host(zonefile_record.target.to_s)
          self.comment = zonefile_record.comment&.to_s
        end
      end

      alias target domainname
    end

    class SRV < Record
      attr_accessor :host, :priority, :weight, :port, :domainname

      def initialize(vars, zonefile_record)
        @vars = vars
        if zonefile_record
          self.host = qualify_host(zonefile_record.host.to_s)
          @vars[:last_host] = host
          self.ttl = zonefile_record.ttl.to_i
          self.klass = zonefile_record.klass.to_s
          self.priority = zonefile_record.priority.to_i
          self.weight = zonefile_record.weight.to_i
          self.port = zonefile_record.port.to_i
          self.domainname = qualify_host(zonefile_record.target.to_s)
          self.comment = zonefile_record.comment&.to_s
        end
      end

      alias target domainname
    end

    class SSHFP < Record
      attr_accessor :host, :alg, :fptype, :fp

      def initialize(vars, zonefile_record)
        @vars = vars
        if zonefile_record
          self.host = qualify_host(zonefile_record.host.to_s)
          @vars[:last_host] = host
          self.ttl = zonefile_record.ttl.to_i
          self.klass = zonefile_record.klass.to_s
          self.alg = zonefile_record.alg.to_i
          self.fptype = zonefile_record.fptype.to_i
          self.fp = zonefile_record.fp.to_s
          self.comment = zonefile_record.comment&.to_s
        end
      end
    end

    class TXT < Record
      attr_accessor :host, :data

      def initialize(vars, zonefile_record)
        @vars = vars
        if zonefile_record
          self.host = qualify_host(zonefile_record.host.to_s)
          @vars[:last_host] = host
          self.ttl = zonefile_record.ttl.to_i
          self.klass = zonefile_record.klass.to_s
          self.data = zonefile_record.data.to_s
          self.comment = zonefile_record.comment&.to_s
        end
      end
    end

    class SPF < TXT
    end
  end
end
