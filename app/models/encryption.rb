require 'manageiq/password'
class Encryption < ApplicationRecord
  acts_as_tenant(:tenant, :has_global_records => true)

  def secret
    secret_encrypted.blank? ? secret_encrypted : ManageIQ::Password.decrypt(secret_encrypted)
  end

  def secret=(val)
    val = ManageIQ::Password.try_encrypt(val) if val.present?
    self.secret_encrypted = val
  end

  def secret_encrypted
    self['secret']
  end

  def secret_encrypted=(val)
    self['secret'] = val
  end
end
