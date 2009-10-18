require 'spec_helper'
require 'dns/zonefile'

describe "DNS::Zonefile" do
  it "should be versioned" do
    lambda {
      DNS::Zonefile.const_get(:VERSION)
    }.should_not raise_error
  end

  it "should be version 0.0.1" do
    DNS::Zonefile::VERSION.should eql("0.0.1")
  end
end
