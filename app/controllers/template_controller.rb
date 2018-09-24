# app/controllers/template_controller.rb
class TemplateController < ApplicationController
  before_action :set_template, only: [:show, :update, :destroy]

  # GET /templates
  def list
    @templates = Template.all
    json_response(@templates)
  end

  # POST /templates
  def create
    @template = Template.create!(template_params)
    json_response(@template, :created)
  end

  # GET /templates/:id
  def show
    json_response(@template)
  end

  # PUT /templates/:id
  def update
    @template.update(template_params)
    head :no_content
  end

  # DELETE /templates/:id
  def destroy
    @template.destroy
    head :no_content
  end

  private

  def template_params
    # whitelist params
    params.permit(:title, :description, :created_by)
  end

  def set_template
    @template = Template.find(params[:id])
  end
end
