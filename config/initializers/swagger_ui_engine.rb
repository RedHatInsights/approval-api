# config/initializers/swagger_ui_engine.rb

SwaggerUiEngine.configure do |config|
  config.swagger_url = {
    v1_0_0: '/approval/v1.0/openapi.json',
  }
end
