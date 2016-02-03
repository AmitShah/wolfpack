class TasksController < ApplicationController
  def index
    @tasks = Task.all
  end
  def new
    @task = Task.new
  end

  def create
    @task = Task.create(medium: params[:task][:medium],
                        target: params[:task][:target],
                        action: params[:task][:action],
                        wolf_count: params[:task][:wolf_count]
                        )
    (1..params[:task][:wolf_count].to_i).each do |job|
      Ticket.create(:task_id => @task.id)
    end
  end
end
