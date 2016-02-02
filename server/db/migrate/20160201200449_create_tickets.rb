class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.integer :task_id
      t.integer :agent_id
      t.integer :wolf_id
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps null: false
    end
  end
end
