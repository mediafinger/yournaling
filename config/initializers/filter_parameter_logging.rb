# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
#
if AppConf.is?(:debug, true) && !AppConf.production_env
  # do not filter parameters in development or test environments when DEBUG=true is set
else
  Rails.application.config.filter_parameters += [
    :Authorization,
    :certificate,
    :crypt,
    :email,
    :first_name,
    :last_name,
    :mobile_number,
    :otp,
    :password, # password_confirmation
    :_key, # private_key
    :salt,
    :secret, # api_credentials.secret
    :ssn,
    :token, # confirmation_token, reset_password_token
  ]
end
