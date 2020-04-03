class Template < ApplicationRecord
  include Metadata

  acts_as_tenant(:tenant, :has_global_records => true)

  has_many :workflows, -> { order(:id => :asc) }, :inverse_of => :template

  validates :title, :presence => :title

  before_destroy :delete_passwords

  def self.seed
    template = find_or_create_by!(:title => 'Basic')
    template.update_attributes(
      :description     => 'A basic approval workflow that supports multi-level approver groups through email notification',
      :process_setting => seed_process_setting(template.process_setting),
      :signal_setting  => seed_signal_setting(template.signal_setting)
    )
  end

  private_class_method def self.seed_process_setting(old_setting)
    return nil unless ENV['APPROVAL_PAM_SERVICE_HOST']
    seed_bpm_setting(old_setting).merge('process_id' => 'MultiStageEmails')
  end

  private_class_method def self.seed_signal_setting(old_setting)
    return nil unless ENV['APPROVAL_PAM_SERVICE_HOST']
    seed_bpm_setting(old_setting).merge('signal_name' => 'nextGroup')
  end

  private_class_method def self.seed_bpm_setting(old_setting)
    old_password_id = old_setting.try(:[], 'password')
    old_password = Encryption.find(old_password_id) if old_password_id

    new_password_id =
      if old_password.try(:secret) == ENV['KIE_SERVER_PASSWORD']
        old_password_id
      else
        old_password.try(:delete)
        Encryption.create!(:secret => ENV['KIE_SERVER_PASSWORD']).id
      end

    {
      'processor_type' => 'jbpm',
      'container_id'   => 'approval',
      'password'       => new_password_id,
      'username'       => ENV['KIE_SERVER_USERNAME'],
      'host'           => "#{ENV['APPROVAL_PAM_SERVICE_HOST']}:#{ENV['APPROVAL_PAM_SERVICE_PORT']}"
    }
  end

  private

  def delete_passwords
    process_password_id = process_setting.try(:[], 'password')
    Encryption.destroy(process_password_id) if process_password_id

    signal_password_id = signal_setting.try(:[], 'password')
    Encryption.destroy(signal_password_id) if signal_password_id
  end

  def policy_name
    TemplatePolicy
  end
end
