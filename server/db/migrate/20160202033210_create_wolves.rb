class CreateWolves < ActiveRecord::Migration
  def change
    create_table :wolves do |t|
      t.string :instance_id
      t.string :ip_address
      t.string :key
      t.timestamps null: false
    end
  end
end
