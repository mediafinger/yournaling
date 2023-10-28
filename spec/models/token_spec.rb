RSpec.describe Token, type: :model do
  let(:payload) { { user_yid: "111", team_yid: "222" }.as_json }
  let(:secret) { "test" }
  let(:type) { "password_reset" }

  context "when valid" do
    it "encodes and decodes a token" do
      token = described_class.encode(payload:)
      decoded = described_class.decode(token:)

      expect(decoded).to eq(payload)
    end
  end

  context "with custom params" do
    it "encodes and decodes a token" do
      token = described_class.encode(payload:, secret:, type:)
      decoded = described_class.decode(token:, secret:, type:)

      expect(decoded).to eq(payload)
    end
  end

  context "with custom expiration_time" do
    it "expires as set" do
      token = described_class.encode(payload:, expires_at: 60.seconds.from_now)

      # 60 seconds expiration time + 60.seconds leeway + 1.second
      travel_to 121.seconds.from_now do
        expect { described_class.decode(token:) }.to raise_error(JWT::ExpiredSignature, "Signature has expired")
      end
    end
  end

  context "when expired" do
    it "raises an error" do
      token = described_class.encode(payload:)

      travel_to 1.hour.from_now do
        expect { described_class.decode(token:) }.to raise_error(JWT::ExpiredSignature, "Signature has expired")
      end
    end
  end

  context "when wrong secret" do
    it "raises an error" do
      token = described_class.encode(payload:, secret:)

      expect { described_class.decode(token:) }.to raise_error(JWT::VerificationError, "Signature verification failed")
    end
  end

  context "when wrong type" do
    it "raises an error" do
      token = described_class.encode(payload:, type:)

      expect { described_class.decode(token:) }.to raise_error(
        JWT::InvalidSubError, "Invalid subject. Expected general, received password_reset"
      )
    end
  end
end
