class RequestListByApproverService
  attr_accessor :username

  def initialize(username)
    self.username = username
  end

  def list
    reqs = []
    group_refs = Group.all(username).map(&:uuid)

    group_refs.each do |group_ref|
      reqs |= Request.all.select do |req|
        req.workflow.group_refs.include?(group_ref)
      end
    end

    Request.includes(:stages).where(:id => reqs.pluck(:id))
  end
end
