class UserContext
  attr_reader :request, :params, :access

  def initialize(request, params, access)
    @request = request
    @params = params
    @access = access
  end
end
