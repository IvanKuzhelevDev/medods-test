module Occurrences
  # A single calendar occurrence — either virtual (computed from the rule) or
  # backed by a materialized TaskOccurrence exception (`exception: true`).
  View = Struct.new(
    :task, :date, :status, :scheduled_at,
    :title, :description, :canceled, :exception, :tags,
    keyword_init: true
  )
end
