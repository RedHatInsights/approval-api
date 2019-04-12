module Response
  def json_response(object, status = :ok)
    render :json => object.as_json(:except => :context), :status => status
  end
end
