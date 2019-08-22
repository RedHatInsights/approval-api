require 'rake'

namespace :approval do
  desc "All kinds of resources cleanup tasks"
  namespace :workflows do
    desc "Cleanup those workflows with empty associated group_refs"
    task :cleanup => :environment do
      puts "Will cleanup workflows with empty group references"
      Workflow.where(:group_refs => []).where.not(:name => "Always approve").destroy_all
    end
  end

  namespace :requests do
    desc "Cleanup those requests older than certain days"
    task :cleanup, [:days] => [:environment] do |_t, args|
      puts "Will cleanup requests created #{args.days} ago"
      ids = Request.where("created_at < ?", Date.today - args.days.to_i).pluck(:id)
      puts "Requests #{ids} will be cleaned up"
      Request.where("created_at < ?", Date.today - args.days.to_i).destroy_all
    end
  end
end
