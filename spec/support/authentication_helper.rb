# Does what Devise::Test::IntegrationHelpers `sign_in(user)` would normally do
#
# Use Login-Form to login
#
def sign_in(user)
  visit login_url
  fill_in :email, with: user.email
  fill_in :password, with: "foobar1234"
  click_button "Login"
end

# Click Logout-Button to logout
#
def sign_out(user)
  click_button "Logout #{user.name}"
end
