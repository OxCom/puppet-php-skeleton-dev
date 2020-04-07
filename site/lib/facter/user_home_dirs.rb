Facter.add(:user_home_dirs) do
    confine kernel: 'Linux'
    setcode do
        home_dirs = {}
        Etc.passwd do |user|
          home_dirs[user.name] = user.dir
        end
        home_dirs
    end
end
