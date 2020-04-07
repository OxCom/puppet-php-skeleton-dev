# user_home_dirs.rb

Facter.add("user_home_dirs") do
  setcode do
    value = Dir.entries(root).select { |entry| File.directory? File.join(root, entry) and not entry.in? %w[. ..]}
  end
end
