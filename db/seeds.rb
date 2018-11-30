Dir.glob(Rails.root.join("app/models/*.rb")).each do |f|
  next unless File.read(f).include?("self.seed")
  klass = File.basename(f, ".*").camelize
  klass.constantize.seed
end
