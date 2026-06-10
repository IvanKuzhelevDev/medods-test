class CreateTaskOccurrences < ActiveRecord::Migration[8.1]
  def change
    create_table :task_occurrences do |t|
      t.references :task, null: false, foreign_key: true
      t.date     :occurrence_date, null: false
      t.string   :status
      t.datetime :scheduled_at
      t.string   :title
      t.text     :description
      t.boolean  :canceled, null: false, default: false
      t.timestamps
    end
    add_index :task_occurrences, [ :task_id, :occurrence_date ], unique: true
  end
end
