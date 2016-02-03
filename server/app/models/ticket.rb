class Ticket < ActiveRecord::Base
  belongs_to :wolf
  belongs_to :agent
  belongs_to :task
end
