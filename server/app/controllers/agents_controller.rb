class AgentsController < ApplicationController
  def index
    @agents = Agent.all
  end
  def new
    @agent = Agent.new
  end
  def create
    @agent = Agent.create(:username => params[:agent][:username],
                          :agent_type => params[:agent][:agent_type],
                          :cookie => params[:agent][:cookie]
                          )
    redirect_to agent_path(@agent)
  end

  def show
    @agent = Agent.find(params[:id])
  end

  def get_agent
    @wolf = Wolf.find_by(ip_address: request.remote_ip)
    agent_type = params[:agent_type]
    @agent = Agent.where(:agent_type => agent_type).where(:available => true).limit(1)
    if @agent.blank?
      render json: {data: "no more agents."}
    else
      @agent.available = false
      @agent.save
      render json: {agent: @agent}
    end
  end

  def make_available
    @agent = Agent.find(params[:agent_id])
    @agent.available = true
    redirect_to agents_path
  end
end
