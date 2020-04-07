Facter.add(:user_home_dirs) do
    setcode do
        value = []

        value = Dir.entries('/home').select {|entry| File.directory? File.join('/home',entry) and !(entry == '.' || entry == '..') }

        value
    end
end
