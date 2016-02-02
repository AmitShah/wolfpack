class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      # reddit, facebook, twitter, etc
      t.string :medium
      # data the agents need (url, username, etc)
      t.string :target
      # action to take
      t.string :action
      # wolves required
      t.integer :wolf_count

      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps null: false
    end
  end
end
