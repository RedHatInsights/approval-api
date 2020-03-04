class RandomAccessKey < ApplicationRecord
  belongs_to :request

  after_initialize do |key|
    key.access_key ||= SecureRandom.hex(16)
  end
end
