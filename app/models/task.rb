class Task < ApplicationRecord
  STATUSES         = %w[new in_progress done canceled].freeze
  RECURRENCE_TYPES = %w[once daily monthly specific_dates parity].freeze
  PARITIES         = %w[even odd].freeze

  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags
  has_many :occurrences, class_name: "TaskOccurrence", dependent: :destroy

  validates :title, presence: true
  # NOTE (reviewed): status transitions are intentionally unrestricted (any -> any).
  # A state machine (e.g. forbid canceled -> done) is a deliberate future extension,
  # out of scope for this assignment.
  validates :status, inclusion: { in: STATUSES }
  validates :recurrence_type, inclusion: { in: RECURRENCE_TYPES }
  validate  :recurrence_params_valid
  validate  :ends_on_after_starts_on

  scope :with_status, ->(status) { where(status: status) if status.present? }
  # Filter by tag via a subquery so a chained `includes(:tags)` is not itself
  # narrowed to the matching tag (the includes + where-on-association trap).
  scope :tagged_with, ->(name) { where(id: Task.joins(:tags).where(tags: { name: name }).select(:id)) if name.present? }

  private

  # Each recurrence type requires its own parameters; validate only what applies.
  def recurrence_params_valid
    case recurrence_type
    when "once"
      errors.add(:starts_on, "обязателен для разовой задачи") if starts_on.blank?
    when "daily"
      errors.add(:starts_on, "обязателен") if starts_on.blank?
      if recurrence_interval.blank? || recurrence_interval < 1
        errors.add(:recurrence_interval, "должен быть >= 1")
      end
    when "monthly"
      errors.add(:starts_on, "обязателен") if starts_on.blank?
      if days_of_month.blank? || days_of_month.any? { |d| !d.between?(1, 31) }
        errors.add(:days_of_month, "должны быть числами от 1 до 31")
      end
    when "specific_dates"
      errors.add(:specific_dates, "не должны быть пустыми") if specific_dates.blank?
    when "parity"
      errors.add(:starts_on, "обязателен") if starts_on.blank?
      errors.add(:parity, "должна быть even или odd") unless PARITIES.include?(parity)
    end
  end

  def ends_on_after_starts_on
    return if starts_on.blank? || ends_on.blank?

    errors.add(:ends_on, "не может быть раньше даты начала") if ends_on < starts_on
  end
end
