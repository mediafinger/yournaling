# clear DB before populating it
[
  User,
  Team,
  Member,
].each do |m|
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{m.table_name} RESTART IDENTITY CASCADE;")
end

# create records

andy = User.create!(email: "andy@example.com", password: "foobar1234", name: "Andy")
dodo = User.create!(email: "dodo@example.com", password: "foobar1234", name: "Dodo")
user = User.create!(email: "user@example.com", password: "foobar1234", name: "User")

rtv = Team.create!(name: "RanTanVan")
team = Team.create!(name: "team")

rtv_owner = Member.create!(user: andy, team: rtv, roles: %w[owner publisher])
rtv_editor = Member.create!(user: dodo, team: rtv, roles: %w[manager editor])

team_editor = Member.create!(user: andy, team:, roles: %w[editor])

# TODO: create picture
# TODO: create weblink
# TODO: create geo-location
# TODO: create memory
# TODO: create chronicle
# TODO: create experience
