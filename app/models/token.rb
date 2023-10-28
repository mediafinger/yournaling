# Store a few per-request attributes here (globally), instead of passing them around everywhere
#
# https://github.com/jwt/ruby-jwt
#
# When setting a secret for e.g. a User's password change, you could salt the secret
# with a part of the users's encrypted password - so once the password changes, the token will no longer be valid.
# Similar could be done for email changes.
#
class Token
  class << self
    def encode(payload:, secret: nil, type: "general", expires_at: 15.minutes.from_now)
      secret ||= Rails.application.credentials.secret_key_base

      JWT.encode(
        {
          data: payload,
          exp: expires_at.to_i,
          nbf: Time.current.to_i,
          iss: "yournaling.com",
          sub: type,
        },
        secret,
        "HS256"
      )
    end

    def decode(token:, secret: nil, type: "general")
      secret ||= Rails.application.credentials.secret_key_base

      decoded_token = JWT.decode(
        token,
        secret,
        true,
        {
          sub: type,
          verify_sub: true,
          nbf_leeway: 60.seconds,
          exp_leeway: 60.seconds,
          iss: "yournaling.com",
          verify_iss: true,
          algorithm: "HS256",
          required_claims: %w[exp nbf iss sub],
        }
      )

      decoded_token.first["data"]
    end
  end
end
