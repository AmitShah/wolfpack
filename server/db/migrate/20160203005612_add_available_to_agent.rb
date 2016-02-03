class AddAvailableToAgent < ActiveRecord::Migration
  def change
    add_column :agents, :available, :boolean, :default => true
  end
end
