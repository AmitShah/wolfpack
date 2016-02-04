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
    redirect_to tasks_path
  end

  def destroy
    Task.destroy(params[:id])
    redirect_to tasks_path
  end

  def close_ticket
    @task = Task.find(params[:task_id])
    @wolf = Wolf.find_by(ip_address: request.remote_ip)
    @agent = Agent.find(params[:agent_id])
    @ticket = Ticket.find_by(:task_id => @task_id, wolf_id: @wolf.id, agent_id: @agent.id)
    @ticket.finished_at = Time.now
    @ticket.save
    render json: @ticket
  end
end
