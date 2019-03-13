module Convertable
  extend ActiveSupport::Concern

  def convert_date_id(attributes_hash)
    attributes_hash.tap do |hash|
      attributes_hash.each_key do |attr_key|
        hash[attr_key] = send(attr_key).iso8601 if attribute(attr_key).kind_of?(Time) && respond_to?(attr_key)
        hash[attr_key] = send(attr_key).to_s if attr_key.ends_with?("_id") || attr_key == "id"
      end
    end
  end
end
