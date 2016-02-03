class TicketsController < ApplicationController
  def index
    @tickets = Ticket.all
  end

  def show
    @ticket = Ticket.find(params[:id])
  end

  def destroy
    Ticket.destroy(params[:id])
    redirect_to tickets_path
  end

end
