class Workflow < ApplicationRecord
  include Metadata
  acts_as_tenant(:tenant)

  default_scope { order(:sequence => :asc) }

  belongs_to :template
  has_many :requests, -> { order(:id => :asc) }, :inverse_of => :workflow
  has_many :tag_links, :dependent => :destroy, :inverse_of => :workflow

  validates :name, :presence => true, :uniqueness => {:scope => :tenant}
  validates :sequence, :uniqueness => { scope: :tenant_id }

  before_validation :new_sequence, :on => :create
  before_validation :move_rest_higher, :on => :update

  def external_processing?
    template&.process_setting.present?
  end

  def external_signal?
    template&.signal_setting.present?
  end

  private

  def table
    self.class.arel_table
  end

  def new_sequence
    return move_rest_higher if sequence

    self.sequence = self.class.last&.sequence.to_i + 1
  end

  # move all related sequence number one higher if the desired number is in use
  def move_rest_higher
    return unless sequence && sequence_changed? && self.class.exists?(:sequence => sequence)

    self.class.where(table[:sequence].gteq(sequence)).update_all("sequence = (-sequence - 1)")
    self.class.where(table[:sequence].lt(0)).update_all("sequence = (-sequence)")
  end
end
