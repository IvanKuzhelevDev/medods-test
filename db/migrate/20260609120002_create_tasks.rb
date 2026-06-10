class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string  :title, null: false
      t.text    :description
      t.string  :status, null: false, default: "new"

      t.string  :recurrence_type, null: false, default: "once"
      t.integer :recurrence_interval
      t.integer :days_of_month, array: true, default: []
      t.date    :specific_dates, array: true, default: []
      t.string  :parity
      t.date    :starts_on
      t.date    :ends_on
      t.time    :due_time

      t.timestamps
    end
    add_index :tasks, :status
    add_index :tasks, :starts_on
  end
end
