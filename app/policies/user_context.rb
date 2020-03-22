class UserContext
  attr_reader :request, :params

  def initialize(request, params)
    @request = request
    @params = params
  end
end
