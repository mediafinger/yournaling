exit unless Rails.env.development?
exit unless AppConf.is?(:environment, :development)

# delete all uploaded files
FileUtils.rm_rf(Dir[Rails.root.join("tmp/storage/")])
ActiveStorage::Blob.all.each(&:purge)

# clear DB before populating it
(ActiveRecord::Base.connection.tables - %w[ar_internal_metadata schema_migrations]).each do |table|
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table} RESTART IDENTITY CASCADE;")
end

# create records

andy = User.create!(email: "andy@example.com", password: "foobar1234", name: "Andy Finger", role: "admin")
dodo = User.create!(email: "dodo@example.com", password: "foobar1234", name: "Dodo Finger")
user = User.create!(email: "user@example.com", password: "foobar1234", name: "User Account")

van = Team.create!(name: "RanTanVan")
team = Team.create!(name: "team two")

van_owner = Member.create!(user: andy, team: van, roles: %w[owner publisher])
van_editor = Member.create!(user: dodo, team: van, roles: %w[manager editor])

team_owner = Member.create!(user:, team:, roles: %w[owner editor])

van_pic = FactoryBot.create(:picture, team: van)

loc = Location.create!(country_code: "es", address: "N-340, Km 79.3, 11380 Tarifa, Cádiz", lat: "36.0523", long: "-5.6487", name: "Tarifa - La Peña", url: "https://www.google.com/maps?q=36.0523,-5.6487", team: van)

weblink = Weblink.create!(name: "Yournaling", url: "www.yournaling.com", description: "Your Journaling", team: van)


# TODO: create memory
# TODO: create chronicle
# TODO: create experience
