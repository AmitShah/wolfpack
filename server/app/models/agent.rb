class Agent < ActiveRecord::Base
  has_many :tickets
  has_many :agent_to_wolves
  has_many :wolves, through: :agent_to_wolves

end
