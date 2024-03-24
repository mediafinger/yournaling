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

andy = User.new(email: "andy@example.com", password: "foobar1234", name: "Andy Finger", role: "admin")
dodo = User.new(email: "dodo@example.com", password: "foobar1234", name: "Dodo Finger")
user = User.new(email: "user@example.com", password: "foobar1234", name: "User Account")
User.create_with_history(record: andy, history_params: { team: Team.new(yid: :none), user: User.new(yid: :admin) })
User.create_with_history(record: dodo, history_params: { team: Team.new(yid: :none), user: User.new(yid: :admin) })
User.create_with_history(record: user, history_params: { team: Team.new(yid: :none), user: User.new(yid: :admin) })

van = Team.new(name: "RanTanVan")
team = Team.new(name: "team two")
Team.create_with_history(record: van, history_params: { team: van, user: User.new(yid: :admin) })
Team.create_with_history(record: team, history_params: { team: team, user: User.new(yid: :admin) })

van_owner = Member.new(user: andy, team: van, roles: %w[owner publisher])
van_editor = Member.new(user: dodo, team: van, roles: %w[manager editor])
team_owner = Member.new(user:, team:, roles: %w[owner editor])
Member.create_with_history(record: van_owner, history_params: { team: van, user: andy })
Member.create_with_history(record: van_editor, history_params: { team: van, user: andy })
Member.create_with_history(record: team_owner, history_params: { team: team, user: user })

van_pic = FactoryBot.build(:picture, team: van)
Picture.create_with_history(record: van_pic, history_params: { team: van, user: andy })

loc = Location.new(country_code: "es", address: "N-340, Km 79.3, 11380 Tarifa, Cádiz", lat: "36.0523", long: "-5.6487", name: "Tarifa - La Peña", url: "https://www.google.com/maps?q=36.0523,-5.6487", team: van)
Location.create_with_history(record: loc, history_params: { team: van, user: andy })

weblink = Weblink.new(name: "Yournaling", url: "www.yournaling.com", description: "Your Journaling", team: van)
Weblink.create_with_history(record: weblink, history_params: { team: van, user: andy })

# TODO: create memory
# TODO: create chronicle
# TODO: create experience
