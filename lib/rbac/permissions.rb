module RBAC
  module Permissions
    ACTION_CREATE_PERMISSION    = 'approval:actions:create'.freeze
    ACTION_READ_PERMISSION      = 'approval:actions:read'.freeze
    REQUEST_CREATE_PERMISSION   = 'approval:requests:create'.freeze
    REQUEST_READ_PERMISSION     = 'approval:requests:read'.freeze
    STAGE_READ_PERMISSION       = 'approval:stages:read'.freeze
    WORKFLOW_APPROVE_PERMISSION = 'approval:workflows:approve'.freeze

    APPROVER_PERMISSIONS = [ACTION_CREATE_PERMISSION, ACTION_READ_PERMISSION, REQUEST_READ_PERMISSION].freeze

    OWNER_PERMISSIONS = [ACTION_CREATE_PERMISSION, REQUEST_CREATE_PERMISSION,
                         REQUEST_READ_PERMISSION, STAGE_READ_PERMISSION].freeze
  end
end
