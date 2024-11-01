# rubocop:disable Rails/Output
# rubocop:disable Style/Alias
Rails.application.console do
  if AppConf.is?(:environment, :development)
    class ApplicationRecord
      class << self
        # e.g. call `RecordEvent>"uuid..."` to find a record
        alias_method :>, :find
      end
    end

    # alias class User to USer (my favority fast-typing typo)
    USer = User

    # for YidEnabled record just type fynd("yid...") to find the record
    def fynd(yid)
      ApplicationRecordYidEnabled.fynd(yid)
    end

    def from_url(yid)
      ApplicationRecordYidEnabled.urlsafe_fynd(yid)
    end

    @andy = User.find_by(email: "andy@example.com")
    @van  = Team.find_by(name: "RanTanVan")

    puts "Yournaling development console - initialized @andy and @van - don't forget about `show_cmds`"
  end
end
# rubocop:enable Rails/Output
# rubocop:enable Style/Alias
