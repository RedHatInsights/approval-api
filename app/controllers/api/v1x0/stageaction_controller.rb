module Api
  module V1x0
    class StageactionController < ActionController::Base
      include Response
      include ExceptionHandler

      protect_from_forgery :with => :exception, :prepend => true

      rescue_from Exceptions::RBACError, Exceptions::ApprovalError, URI::InvalidURIError, ArgumentError do |e|
        response.body = e.message
        render :status => :internal_server_error, :action => :result
      end

      rescue_from ActionController::ParameterMissing do |_e|
        response.body = "The Reason/Memo field is required for [Deny/Memo] actions"
        render :status => :unprocessable_entity, :action => :result
      end

      rescue_from Exceptions::InvalidStateTransitionError do |_e|
        response.body = "Your action cannot be executed. Somebody else may have approved/denied this request at the mean time."
        render :status => :unprocessable_entity, :action => :result
      end

      before_action :set_stage, :only => [:show, :update]

      def show
      end

      def update
        operation = params.require(:commit)
        case operation
        when 'Memo', 'Deny'
          comments = params.require(:message)
        else
          comments = params[:message]
        end

        ManageIQ::API::Common::Request.with_request(@stage.request.context.transform_keys(&:to_sym)) do
          ActsAsTenant.with_tenant(Tenant.find(@stage.tenant_id)) do
            ActionCreateService.new(@stage.id).create(
              'operation'    => operation.downcase,
              'processed_by' => @approver,
              'comments'     => comments
            )
          end
        end

        render :result
      end

      private

      def set_stage
        set_view_path
        set_resources

        @approver = Base64.decode64(params.require(:approver))
        @stage = Stage.find_by(:random_access_key => params.require(:id))

        if @stage
          @order = set_order
        else
          response.body = "Your request [#{params[:id]}] is either expired or has been processed!"
          render :status => :internal_server_error, :action => :result
        end
      end

      def set_order
        request = @stage.request
        {
          :orderer       => request.requester,
          :product       => request.content["product"],
          :portfolio     => request.content["portfolio"],
          :platform      => request.content["platform"],
          :order_id      => request.content["order_id"],
          :order_date    => Time.zone.parse(request.created_at.to_s).strftime("%m/%d/%Y"),
          :order_time    => Time.zone.parse(request.created_at.to_s).strftime("%I:%M %p"),
          :order_content => request.content["params"]
        }
      end

      def set_view_path
        prepend_view_path(Rails.root.join('app', 'controllers'))
      end

      def set_resources
        @resources = { :approval_web_logo    => ENV['APPROVAL_WEB_LOGO'],
                       :approval_web_product => ENV['APPROVAL_WEB_PRODUCT'] }
      end
    end
  end
end
