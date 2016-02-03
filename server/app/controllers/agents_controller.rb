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

  # we use available in the agent for now, because of dumb reasons. This should either resolve to a single agent -> wolf, or allow explicit agent<:medium> -> wolf relationships

  def get_agent
    @wolf = Wolf.find_by(ip_address: request.remote_ip)
    agent_type = params[:agent_type]
    @agent = Agent.where(:agent_type => agent_type).where(:available => true)
    if @agent.blank?
      render json: {data: "no more agents."}
    else
      @agent = @agent.first
      @agent.available = false
      @agent.save
      AgentToWolf.create(:agent_id => @agent.id, :wolf_id => @wolf.id)
      render json: {agent: @agent}
    end
  end

  def unload_agent
    @wolf = Wolf.find_by(ip_address: request.remote_ip)
    @agent = Agent.find(params[:agent_id])
    @aw = AgentToWolf.find_by(:agent_id => @agent.id, :wolf_id => @wolf.id)
    AgentToWolf.destroy(@aw.id)
    @agent.available = true
    @agent.save
  end

  def make_available
    @agent = Agent.find(params[:agent_id])
    @agent.available = true
    @aw = AgentToWolf.where(:agent_id => @agent.id)
    @aw.each do |aw|
      AgentToWolf.destroy(aw.id)
    end
    @agent.save
    redirect_to agents_path
  end

  def store_agent
    @agent = Agent.create(username: params[:username], cookie: params[:cookies], agent_type: params[:agent_type])
    render json: @agent
  end

  def get_ticket
    begin
      @agent = Agent.find(params[:agent_id])
      @wolf = Wolf.find_by(ip_address: request.remote_ip)
      if Ticket.where(wolf_id: @wolf.id, agent_id: @agent.id)
        raise "Already got a ticket."
      end
      @ticket = Ticket.where(wolf_id: nil, agent_id: nil).first
      @ticket.wolf_id = @wolf.id
      @ticket.agent_id = @agent.id
      @ticket.started_at = Time.now
      @ticket.save
    rescue => e
      render json: {status: false}
    end
    @task = @ticket.task
    render json: {status: true, data: @task}
  end

end
