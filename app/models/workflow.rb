class Workflow < ApplicationRecord
  include Metadata
  acts_as_tenant(:tenant)

  default_scope { order(:internal_sequence => :asc) }

  belongs_to :template
  before_destroy :validate_deletable, :prepend => true
  after_commit :send_deletion_message
  has_many :requests, -> { order(:id => :asc) }, :inverse_of => :workflow, :dependent => :nullify
  has_many :tag_links, :dependent => :destroy, :inverse_of => :workflow

  validates :name, :presence => true, :uniqueness => {:scope => :tenant}
  validates :sequence, :uniqueness => {:scope => :tenant_id}

  before_validation :assign_new_internal_sequence, :on => :create
  before_validation :adjust_sequences, :on => :update
  after_save        :validate_positive_sequences
  before_destroy    :sequence_lower
  after_destroy     :validate_positive_sequences

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

    target_sequence = sequence + delta
    if target_sequence < 1
      target_sequence = 1
    else
      largest = last_sequence
      target_sequence = largest if target_sequence > largest
    end
    self.sequence = target_sequence

    save!
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

  def send_deletion_message
    EventService.new(nil).workflow_deleted(id)
  end

  def table
    self.class.arel_table
  end

  # to be removed
  def new_sequence
    throw :abort if sequence && sequence <= 0

    largest = last_sequence
    if sequence && sequence < last_sequence
      sequence_higher(sequence)
    else
      self.sequence = largest + 1 # auto_assignment if sequence is nil or too large
    end
  end

  # to be removed
  # no gap between sequences
  def adjust_sequences
    return unless sequence_changed?

    throw :abort if sequence && sequence <= 0

    largest = last_sequence
    self.sequence = largest if sequence.nil? || sequence > largest

    adjust_sequence_and_internal_sequence(sequence - sequence_was) unless sequence == sequence_was
  end

  # to be removed
  # sequences increment between [sequence sequence_was sequence)
  def sequence_higher(startp, endp = nil)
    change_sequences_to_negative(startp, endp, -1)
    change_sequences_to_positive(endp ? -endp - 1 : nil)
  end

  # to be removed
  # sequences decrement between [startp endp]
  def sequence_lower(startp = sequence, endp = nil)
    change_sequences_to_negative(startp, endp, 1)
    change_sequences_to_positive(-startp + 1)
  end

  # to be removed
  def change_sequences_to_negative(startp, endp, delta)
    query = self.class.reorder(:id).where(table[:sequence].gteq(startp))
    query = query.where(table[:sequence].lteq(endp)) if endp
    query.update_all(["sequence = (-sequence + (?))", delta])
  end

  # to be removed
  def change_sequences_to_positive(exceptp)
    query = self.class.reorder(:id).where(table[:sequence].lt(0))
    query = query.where.not(:sequence => exceptp) if exceptp
    query.update_all("sequence = (-sequence)")
  end

  # to be removed
  def last_sequence
    self.class.last&.sequence.to_i
  end

  # to be removed
  def validate_positive_sequences
    raise Exceptions::NegativeSequence, "Internal error caused by concurrency. Please try again" if self.class.where(table[:sequence].lteq(0)).exists?
  end

  def adjust_sequence_and_internal_sequence(delta)
    Workflow.transaction do
      if delta > 0
        self.internal_sequence = internal_sequence_plus(delta)
        sequence_lower(sequence - delta, sequence)  # to be removed
      else
        self.internal_sequence = internal_sequence_minus(-delta)
        sequence_higher(sequence, sequence - delta) # to be removed
      end
    end
  end

  def internal_sequence_plus(delta)
    range = internal_sequence_range(self.class.where(table[:internal_sequence].gt(internal_sequence)), delta)
    return internal_sequence_extend_from_last if range.empty?

    range.one? ? range.first + 1 : (range.first + range.last) / 2
  end

  def internal_sequence_minus(delta)
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
    new_sequence # to be removed
    self.internal_sequence = internal_sequence_extend_from_last
  end
end
