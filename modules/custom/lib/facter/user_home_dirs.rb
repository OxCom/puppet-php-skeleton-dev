Facter.add(:user_home_dirs) do
    setcode do
        home_dirs = {}
        Etc.passwd do |user|
            if user.uid >= 1000 and File.directory? user.dir
                home_dirs[user.name] = user.dir
            end
        end
        home_dirs
    end
end
