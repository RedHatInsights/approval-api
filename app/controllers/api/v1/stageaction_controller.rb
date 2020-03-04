module Api
  module V1
    class StageactionController < ActionController::Base
      include Response

      protect_from_forgery :with => :exception, :prepend => true

      rescue_from Exceptions::RBACError, URI::InvalidURIError, ArgumentError do |e|
        response.body = e.message
        render :status => :internal_server_error, :action => :result
      end

      rescue_from Exceptions::ApprovalError do |e|
        response.body = e.message
        render :status => :bad_request, :action => :result
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

        Insights::API::Common::Request.with_request(@request.context.transform_keys(&:to_sym)) do
          ActsAsTenant.with_tenant(Tenant.find(@request.tenant_id)) do
            ActionCreateService.new(@request.id).create(
              :operation    => operation.downcase,
              :processed_by => @approver,
              :comments     => comments
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
        @request = Request.find_by(:random_access_key => params.require(:id))

        if @request
          @order = set_order
        else
          response.body = "Your request is either expired or has been processed!"
          render :status => :internal_server_error, :action => :result
        end
      rescue ActionController::ParameterMissing => e
        response.body = e.message
        render :status => :internal_server_error, :action => :result
      end

      def set_order
        request = @request
        {
          :orderer       => request.requester_name,
          :product       => request.content["product"],
          :portfolio     => request.content["portfolio"],
          :order_id      => request.content["order_id"],
          :platform      => request.content["platform"],
          :order_date    => request.created_at.getutc.strftime("%d %B %Y"),
          :order_time    => request.created_at.getutc.strftime("%H:%M UTC"),
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
