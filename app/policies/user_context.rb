class UserContext
  attr_reader :request, :params, :controller_name

  def initialize(request, params, controller_name)
    @request = request
    @params = params
    @controller_name = controller_name
  end
end
