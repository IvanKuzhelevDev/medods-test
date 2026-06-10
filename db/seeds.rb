# Seeds. Idempotent — safe to run repeatedly (executed on db:prepare/db:setup).
#
# The three mandatory, protected system tags. They must always exist and may
# not be renamed or deleted (enforced in app/models/tag.rb).
Tag::SYSTEM_NAMES.each do |name|
  Tag.find_or_create_by!(name: name) { |t| t.system = true }
end
