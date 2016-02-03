class CreateAgentToWolves < ActiveRecord::Migration
  def change
    create_table :agent_to_wolves do |t|
      t.integer :wolf_id
      t.integer :agent_id
      t.timestamps null: false
    end
  end
end
