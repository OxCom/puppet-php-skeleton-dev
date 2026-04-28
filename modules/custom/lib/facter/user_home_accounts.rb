require 'etc'

Facter.add(:user_home_accounts) do
  setcode do
    accounts = []

    Etc.passwd do |entry|
      next unless entry.dir.start_with?('/home/')
      next unless File.directory?(entry.dir)

      group = begin
        Etc.getgrgid(entry.gid).name
      rescue StandardError
        entry.name
      end

      accounts << {
        'user'  => entry.name,
        'group' => group,
        'home'  => entry.dir,
      }
    end

    accounts.sort_by { |item| item['home'] }
  end
end
