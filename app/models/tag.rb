class Tag < ApplicationRecord
  # These three tags must always exist and may not be renamed or deleted.
  SYSTEM_NAMES = %w[отчётность операции звонок].freeze

  has_many :task_tags, dependent: :destroy
  has_many :tasks, through: :task_tags

  validates :name, presence: true,
                   uniqueness: { case_sensitive: false }

  before_update :prevent_system_modification
  # prepend so the protection guard runs before the association's
  # `dependent: :destroy` cascade — a protected tag is never even partially torn down.
  before_destroy :prevent_system_destroy, prepend: true

  scope :system_tags, -> { where(system: true) }

  private

  def prevent_system_modification
    return unless system?
    return unless will_save_change_to_name? || will_save_change_to_system?

    errors.add(:base, "Системные теги нельзя изменять")
    throw :abort
  end

  def prevent_system_destroy
    return unless system?

    errors.add(:base, "Системные теги нельзя удалять")
    throw :abort
  end
end
