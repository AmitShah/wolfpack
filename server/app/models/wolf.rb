class Wolf < ActiveRecord::Base
  has_many :tickets

  has_many :agent_to_wolves
  has_many :agents, through: :agent_to_wolves

end
