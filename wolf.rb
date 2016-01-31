require 'selenium-webdriver'
require 'JSON'
require 'SecureRandom'

class Wolf
  def initialize
    puts "Woof woof."
    @driver = nil
    @agents_file = './wolves.txt'
  end

  def connect
    @driver = Selenium::WebDriver.for :firefox
  end

  def create_user
    @driver.navigate.to "https://www.reddit.com/login"
    @driver.manage.delete_all_cookies
    # in the future we should take a username and shift a char up or down one
    username = SecureRandom.hex(6)
    password = username + "wolf"

    element = @driver.find_element(:id, 'user_reg')
    element.send_keys username

    element = @driver.find_element(:id, 'passwd_reg')
    element.send_keys password

    element = @driver.find_element(:id, 'passwd2_reg')
    element.send_keys password

    element.submit

    wait = Selenium::WebDriver::Wait.new(:timeout => 20)
    wait.until { @driver.find_element(:class => "logout") }

    agent = Hash.new
    agent[:username] = username
    agent[:cookies]  = @driver.manage.all_cookies

    self.write_agent(agent)
  end

  def load_agents
    agents = File.read(@agents_file)
    agents = agents.split("\n")
    parsed_agents = []
    agents.each do |agent|
      parsed_agents.push(JSON.parse(agent))
    end
    return parsed_agents
  end

  def become_agent(agent)
    @driver.navigate.to "https://www.reddit.com/login"
    @driver.manage.delete_all_cookies
    puts "Becoming agent: "+agent["username"]
    cookies = agent["cookies"]
    cookies.each do |c|
      begin
        @driver.manage.add_cookie(name: c["name"], value: c["value"], path: c["path"], domain: c["domain"], expires: Time.new(c["expires"]))
      rescue => e
        puts e
        puts c
      end
    end
    @driver.navigate.to "https://www.reddit.com/login"
  end

  def write_agent(agent)
    f = File.new(@agents_file, "a+")
    f.write(agent.to_json+"\n")
  end

  def quit
    @driver.quit
  end
end

@wolf = Wolf.new
agents = @wolf.load_agents
@driver = @wolf.connect
@wolf.create_user
#@wolf.become_agent(agents[2])
#@wolf.quit