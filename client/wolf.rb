require 'selenium-webdriver'
require 'JSON'
require 'SecureRandom'
require "net/http"
require "uri"
# move reddit concerns here
# require "lib/reddit"

class Wolf
  def initialize
    @driver = nil
    @pid_file = '/tmp/wolf.pid'
    @agent = nil
    @task = nil
    instance_check
    health_check
    while @agent.nil?
      load_agent("reddit")
      sleep(1)
    end
    start_driver
    become_agent
    while(true)
      lurk
    end
  end

  def instance_check
    if File.exist?(@pid_file)
      last_known_pid = File.read(@pid_file)
      begin
        Process.getpgid( last_known_pid.to_i )
        puts "Previous pid file found and process running."
        exit
      rescue => e
        puts "Cleaning up previous pid file"
        File.delete(@pid_file)
      end
    else
      puts "Writing new pid file: #{@pid_file}"
      f = File.new(@pid_file, "w+")
      f.write(Process.pid)
    end
  end

  def health_check
    puts "Woof woof."
    puts "DEN_ADDR: #{ENV["DEN_ADDR"]}"
    unless ENV.has_key?("WOLF_KEY")
      uri = URI.parse(ENV["DEN_ADDR"]+'/wolf/get_key')
      response = Net::HTTP.get(uri)
      wolf_res = JSON.parse(response)
      if wolf_res.has_key?("key")
        ENV['WOLF_KEY'] = wolf_res["key"]
      else
        puts "No more wolfies jumping on the bed."
      end
      puts "Got wolf key: #{ENV['WOLF_KEY']}"
    end
    #vars = ["DEN_ADDR", "WOLF_KEY"]
    #vars.each do |var|
    #  unless ENV.has_key?(var.to_s)
    #    puts "Missing #{var}. Please check environment configs"
    #    exit
    #  end
    #end
  end

  def check_in
    puts "Checking in ****"
    uri = URI.parse(ENV["DEN_ADDR"]+'/agents/'+@agent["id"].to_s+'/get_ticket')
    response = Net::HTTP.get(uri)
    response = JSON.parse(response)
    if response.has_key?("data")
      @task = response["data"]
      puts "Task received ****"
      return true
    else
      return false
    end
  end

  def complete_task
    # medium, target, action, param
    # reddit, url, vote
    self.send(@task["action"], @task["target"])
  end

  def start_driver
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

    @agent = Hash.new
    @agent[:username] = username
    @agent[:cookie]  = @driver.manage.all_cookies

    self.store_agent
  end

  def unload_agent
    puts "Unloading agent: " + @agent["id"].to_s
    uri = URI.parse(ENV["DEN_ADDR"]+'/agents/'+@agent["id"].to_s+'/unload_agent')
    response = Net::HTTP.get(uri)
  end

  def load_agent(agent_type = "reddit")
    uri = URI.parse(ENV["DEN_ADDR"]+'/agents/get_agent?agent_type='+agent_type)
    response = Net::HTTP.get(uri)
    response = JSON.parse(response)
    if response.has_key?("agent")
      @agent = response["agent"]
      puts "Loaded agent: " + @agent["id"].to_s
      if !@ticket.nil?
        # register ticket
      end
      return true
    else
      puts "No more agents. Generate more"
      return false
    end
  end

  def become_agent
    if @agent.nil?
      puts "Please load an agent before proceeding."
      return false
    end
    @driver.navigate.to "https://www.reddit.com/login"
    @driver.manage.delete_all_cookies
    puts "Becoming agent: "+@agent["username"]
    cookies = JSON.parse(@agent["cookie"])
    cookies.each do |c|
      begin
        if c["expires"] == nil
          @driver.manage.add_cookie(name: c["name"], value: c["value"], path: c["path"], domain: c["domain"])
        else
          @driver.manage.add_cookie(name: c["name"], value: c["value"], path: c["path"], domain: c["domain"], expires: Time.new(c["expires"]))
        end
      rescue => e
        puts e
        puts c
      end
    end
    @driver.navigate.to "https://www.reddit.com/login"
    #agent_file = "/tmp/wolf.agent"
    #if File.exist?(agent_file)
    #  puts "Previous agent file found. Exiting"
    #  exit
    #else
    #  f = File.new(agent_file, "w+")
    #  f.write(@agent["id"])
    #end
    return true
  end

  def store_agent
    uri = URI.parse(ENV["DEN_ADDR"]+'/agents/'+@agent["id"].to_s+'/store_agent')
    response = Net::HTTP.post_form(uri, {"agent_type" => "reddit", "wolf_key" => ENV["WOLF_KEY"], "username" => @agent["username"], "cookie" => @agent["cookie"]})
  end

  def quit
    @driver.quit
  end


  def lurk(subreddit = nil)
    if @agent.nil?
      puts "Generate agent before lurking."
      exit
    end
    # list of subreddits to lurk
    subreddits = subreddit || ["entrepreneur/", "startups/", "finance/", "artificial/", "machinelearning/", "robotics/"].shuffle
    # subreddit pages
    pages = ["top/", "new/", "rising/", "controversial/"].shuffle

    time = ["hour", "week", "month", "year", "all"].shuffle

    url = "https://www.reddit.com/r/"

    subreddits.each do |subreddit|
      pages.each do |page|
        if self.check_in
          complete_task
          puts "Resuming Lurking..."
        end
        main_page = url + subreddit + page + "?t=" + time[0]
        puts "Lurking on #{main_page}"

        @driver.navigate.to main_page
        wait = Selenium::WebDriver::Wait.new(:timeout => 20)
        wait.until { @driver.find_element(:class => "sidecontentbox") }

        comment_links = @driver.find_elements(:class, 'comments')

        # This offers us a chance to look seemingly random, while not iterating through *every* link
        if comment_links.size > 0
          comment_links.sample.click
          wait = Selenium::WebDriver::Wait.new(:timeout => 20)
          wait.until { @driver.find_element(:class => "usertext-edit") }

          title = @driver.find_element(:css, '.sitetable a.title').text
          # random vote
          if [true, false].sample
            @driver.find_element(:css, '.up').click
            puts "Title: "+title+" :: UPVOTED"
          else
            @driver.find_element(:css, '.down').click
            puts "Title: "+title+" :: DOWNVOTED"
          end
          sleep(rand(20))
          @driver.navigate.back
        else
          puts "No comments. check the url and try again"
        end
      end
    end
  end

  def vote(target, upvote = true)
    # parse subreddit
    parsed_link = reddit_link_parse(target)
    # search through pages for link
    subreddit_page = "https://www.reddit.com/r/"+parsed_link["subreddit"]
    puts "Looking for: " + target
    puts "Crawling on: " + subreddit_page
    @driver.navigate.to subreddit_page

    uuid = parsed_link["uuid"]

    while true
      begin
        element = @driver.find_element(:xpath, "/html/body//a[contains(@href,'#{uuid}')]")
      rescue => e
        element = @driver.find_element(:partial_link_text, 'next')
        element.click
        next
      end
      # once the link is found, click it
      element.click

      wait = Selenium::WebDriver::Wait.new(:timeout => 20)
      wait.until { @driver.find_element(:class => "usertext-edit") }
      if upvote == true
        @driver.find_element(:css, '.up').click
        puts "UPVOTED"
      else
        @driver.find_element(:css, '.down').click
        puts "DOWNVOTED"
      end
      break
    end
  end

  def endorse
    # go through and upvote all the comments
  end

  def denounce

  end

  def reddit_link_parse(link)
    link = link.split("/")
    #["https:", "", "www.reddit.com", "r", "bigdata", "comments", "43kwgf", "spotify_big_data_wouter_de_bie_big_data_architect"]
    return {"domain" => link[2], "subreddit" => link[4], "uuid" => link[6], "slug" => link[7] }
  end

  def at_exit
    puts "Adios."
    pid_file = "/tmp/wolf.pid"
    current_pid = Process.pid
    if File.exists?(pid_file)
      running_pid = File.read(pid_file)
      if current_pid == running_pid
        puts "Cleaning up: #{pid_file}"
        File.destroy(pid_file)
      end
    end
  end
end

@wolf = Wolf.new