class TaskOccurrence < ApplicationRecord
  belongs_to :task

  validates :occurrence_date, presence: true,
                              uniqueness: { scope: :task_id }
  validates :status, inclusion: { in: Task::STATUSES }, allow_nil: true
  validate  :date_is_a_real_slot

  private

  # An occurrence may only be materialized for a date the series actually
  # schedules. Reschedules change scheduled_at (the time), never occurrence_date,
  # so the anchor date always stays "on schedule".
  def date_is_a_real_slot
    return if occurrence_date.blank? || task.blank?

    scheduled = Recurrence::Generator.new(task).dates_between(occurrence_date, occurrence_date)
    return if scheduled.include?(occurrence_date)

    errors.add(:occurrence_date, "не входит в расписание задачи")
  end
end
