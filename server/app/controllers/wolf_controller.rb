class WolfController < ApplicationController
  def get_key
    @wolf = Wolf.where(ip_address: request.remote_ip).first
    if @wolf.blank?
      @wolf = Wolf.where(ip_address: nil).first
      if @wolf.blank?
        render json: {info: "No more wolfies jumping on the bed"}
      else
        @wolf.ip_address = request.remote_ip
        @wolf.save
        render json: {key: @wolf.key}
      end
    else
      render json: {key: @wolf.key}
    end
    # check in now
  end
end
