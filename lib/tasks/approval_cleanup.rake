require 'rake'

namespace :approval do
  desc "Resource cleanup tasks"
  namespace :workflows do
    desc "Cleanup workflows with empty associated group references"
    task :cleanup => :environment do
      workflows = Workflow.where(:group_refs => []).where.not(:name => "Always approve")
      puts "The follow workflows with empty group references will be deleted:  #{workflows.pluck(:id, :name)}"
      workflows.destroy_all
    end
  end

  namespace :requests do
    desc "Cleanup requests older than specified days"
    task :cleanup, [:days] => [:environment] do |_t, args|
      days = Integer(args.days)

      if days.zero?
        puts "Not allowed to delete all requests in this task"
        exit
      end

      requests = Request.where("created_at < ?", Time.zone.today - days)
      puts "Requests older than #{days} days will be deleted: #{requests.pluck(:id)}"
      requests.destroy_all
    end
  end
end
