exit unless Rails.env.development?
exit unless AppConf.is?(:environment, :development)

# delete all uploaded files
FileUtils.rm_rf(Dir[Rails.root.join("tmp/storage/")])

# clear DB before populating it
[
  User,
  Team,
  Member,
  Picture,
].each do |m|
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{m.table_name} RESTART IDENTITY CASCADE;")
end

# create records

andy = User.create!(email: "andy@example.com", password: "foobar1234", name: "Andy Finger")
dodo = User.create!(email: "dodo@example.com", password: "foobar1234", name: "Dodo Finger")
user = User.create!(email: "user@example.com", password: "foobar1234", name: "User Account")

van = Team.create!(name: "RanTanVan")
team = Team.create!(name: "team two")

van_owner = Member.create!(user: andy, team: van, roles: %w[owner publisher])
van_editor = Member.create!(user: dodo, team: van, roles: %w[manager editor])

team_owner = Member.create!(user:, team:, roles: %w[owner editor])

van_pic = FactoryBot.create(:picture, team: van)

# TODO: create weblink
# TODO: create geo-location
# TODO: create memory
# TODO: create chronicle
# TODO: create experience
