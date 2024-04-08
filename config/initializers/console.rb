# rubocop:disable Rails/Output
Rails.application.console do
  if AppConf.is?(:environment, :development)
    @andy = User.find_by(email: "andy@example.com")
    @van  = Team.find_by(name: "RanTanVan")

    puts "Yournaling development console - initialized @andy and @van - don't forget about `show_cmds`"
  end
end
# rubocop:enable Rails/Output
