module DNS
  module ResourceRecord
    class SOA
      attr_reader :ns, :rp, :serial, :refresh, :retry, :expires, :ttl
    end
  end
end