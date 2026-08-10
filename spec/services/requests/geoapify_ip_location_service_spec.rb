# frozen_string_literal: true

require "rails_helper"

RSpec.describe Requests::GeoapifyIpLocationService, type: :service do
  let(:ip_address) { "80.58.67.250" }
  let(:endpoint_url) { "#{AppConf.geoapify_api_url}/v1/ipinfo?apiKey=#{AppConf.geoapify_api_key}&ip=#{ip_address}" }

  describe ".call" do
    context "when API response is successful" do
      before do
        stub_request(:get, endpoint_url).to_return(
          status: 200,
          body: {
            city: { name: "Malaga" },
            country: { name: "Spain", flag: "🇪🇸" },
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "returns formatted city, flag, and country name" do
        result = described_class.call(ip_address: ip_address)
        expect(result).to eq(["Malaga", "🇪🇸", "Spain"])
      end
    end

    context "when API response is missing location details" do
      before do
        stub_request(:get, endpoint_url).to_return(
          status: 200,
          body: {}.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "falls back to returning an array with the ip_address" do
        result = described_class.call(ip_address: ip_address)
        expect(result).to eq([ip_address])
      end
    end

    context "when API request fails" do
      before do
        stub_request(:get, endpoint_url).to_return(status: 500)
      end

      it "falls back to returning an array with the ip_address" do
        result = described_class.call(ip_address: ip_address)
        expect(result).to eq([ip_address])
      end
    end
  end
end
