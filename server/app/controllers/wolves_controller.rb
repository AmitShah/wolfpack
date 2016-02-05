class WolvesController < ApplicationController

  def index
    @wolves = Wolf.all
  end

  def new
    @wolf = Wolf.new
  end

  def create
    # USING --
    # SECURITY: group-id sg-b071b7d7
    # AMI - ami-d440a6e7 CentOS 7 (x86_64) with Updates HVM - US West (Oregon)
    # AMI DESCR : https://aws.amazon.com/marketplace/ordering?productId=b7ee8a69-ee97-4a49-9e68-afaee216db2e&ref_=dtl_psb_continue&region=us-east-1
    # REGION: US West (Oregon)
    wolf_count = params['wolves']['wolves_count']

    client = Aws::EC2::Client.new(region: 'us-west-2')
    resource = Aws::EC2::Resource.new(client: client)
    instances = resource.create_instances(
      :image_id => 'ami-224bad42',
      :instance_type => 't2.nano',
      :security_groups => ['WOLFPACK'],
      :key_name => 'WOLFPACK',
      :min_count => wolf_count,
      :max_count => wolf_count
      )
    instances.each do |ins|
      wolf_key = SecureRandom.hex(16)
      Wolf.create(instance_id: ins.id, ip_address: ins.public_ip_address, key: wolf_key)
    end
    # update ip_addresses
    @wolves = Wolf.where(ip_address: nil)
    @wolves.each do |w|
      ip_address = w.ip_address
      while(ip_address.blank?)
        ip_address = resource.instance(w.instance_id).public_ip_address
      end
      w.ip_address = ip_address
      w.save
    end

    redirect_to wolves_path
  end

  def edit
  end

  def show
    @wolf = Wolf.find(params[:id])
    client = Aws::EC2::Client.new(region: 'us-west-2')
    resource = Aws::EC2::Resource.new(client: client)
    @instance = resource.instance(@wolf.instance_id)
  end

  def destroy
    @wolf = Wolf.find(params[:id])
    client = Aws::EC2::Client.new(region: 'us-west-2')
    resource = Aws::EC2::Resource.new(client: client)
    instance = resource.instance(@wolf.instance_id)
    instance.terminate
    Wolf.destroy(@wolf.id)
    redirect_to wolves_path
  end
end
