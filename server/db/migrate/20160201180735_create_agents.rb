class CreateAgents < ActiveRecord::Migration
  def change
    create_table :agents do |t|
      t.string :username
      t.text :cookie
      t.string :agent_type
      t.timestamps null: false
    end
  end
end
