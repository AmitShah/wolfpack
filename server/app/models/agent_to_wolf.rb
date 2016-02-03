class AgentToWolf < ActiveRecord::Base
  belongs_to :wolf
  belongs_to :agent
end
