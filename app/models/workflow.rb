class Workflow < ApplicationRecord
  include Metadata
  acts_as_tenant(:tenant)

  default_scope { order(:internal_sequence => :asc) }

  belongs_to :template
  before_destroy :validate_deletable, :prepend => true
  has_many :requests, -> { order(:id => :asc) }, :inverse_of => :workflow, :dependent => :nullify
  has_many :tag_links, :dependent => :destroy, :inverse_of => :workflow

  validates :name, :presence => true, :uniqueness => {:scope => :tenant}

  before_validation :assign_new_internal_sequence, :on => :create
  validate :positive_internal_sequence

  def external_processing?
    template&.process_setting.present?
  end

  def external_signal?
    template&.signal_setting.present?
  end

  def metadata
    super.merge(:object_dependencies => object_dependencies)
  end

  def deletable?
    requests.any? { |request| !request.finished? } ? false : true
  end

  # move current record up or down relative to other records. delta is an integer
  def move_internal_sequence(delta)
    return if delta == 0

    new_sequence = delta > 0 ? internal_sequence_plus(delta) : internal_sequence_minus(-delta)
    update!(:internal_sequence => new_sequence)
  end

  private

  def validate_deletable
    throw :abort unless deletable?
  end

  def object_dependencies
    {}.tap do |dependencies|
      tag_links.pluck(:app_name, :object_type).uniq.each do |key, value|
        dependencies[key] ||= []
        dependencies[key] << value
      end
    end
  end

  def table
    self.class.arel_table
  end

  def internal_sequence_plus(delta)
    return internal_sequence_extend_from_last if delta == Float::INFINITY

    range = internal_sequence_range(self.class.where(table[:internal_sequence].gt(internal_sequence)), delta)
    return internal_sequence_extend_from_last if range.empty?

    range.one? ? range.first + 1 : (range.first + range.last) / 2
  end

  def internal_sequence_minus(delta)
    return internal_sequence_before_first if delta == Float::INFINITY

    range = internal_sequence_range(self.class.reorder('internal_sequence DESC').where(table[:internal_sequence].lt(internal_sequence)), delta)
    return internal_sequence_before_first if range.empty?

    range.one? ? range.first / 2 : (range.first + range.last) / 2
  end

  def internal_sequence_range(query, delta)
    query.select(:internal_sequence).offset(delta - 1).limit(2).collect(&:internal_sequence)
  end

  def internal_sequence_extend_from_last
    self.class.select(:internal_sequence).last&.internal_sequence.to_i + 1 # next integer
  end

  def internal_sequence_before_first
    self.class.select(:internal_sequence).first.internal_sequence / 2
  end

  def assign_new_internal_sequence
    self.internal_sequence = internal_sequence_extend_from_last
  end

  def positive_internal_sequence
    errors.add(:internal_sequence, 'must be positive') unless internal_sequence > 0
  end
end
