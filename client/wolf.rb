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
    @agents_file = './wolves.txt'
    @pid_file = '/tmp/wolf.pid'
    instance_check
    health_check
    check_in
  end

  def instance_check
    if File.exist?(@pid_file)
      puts "Previuos pid file found. Exiting"
      exit
    else
      f = File.new(@pid_file, "w+")
      f.write(Process.pid)
    end
  end

  def health_check
    puts "Woof woof."
    unless ENV.has_key?("WOLF_KEY")
      uri = URI.parse(ENV["DEN_ADDR"]+'/agents/wolf_key')
      response = NET::HTTP.get(uri)
      raise response.inspect
    end
    # check for environment variables
    # keys to check for
    #vars = ["DEN_ADDR", "WOLF_KEY"]
    #vars.each do |var|
    #  unless ENV.has_key?(var.to_s)
    #    puts "Missing #{var}. Please check environment configs"
    #    exit
    #  end
    #end
  end

  def check_in
    # send an update of health
    # last_lurk
    uri = URI.parse(ENV["DEN_ADDR"]+'/agents/check_in')
    response = Net::HTTP.post_form(uri, {"WOLF_KEY" => ENV["WOLF_KEY"], "LAST_LURK" => Time.now})
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

    self.store_agent(agent)
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
    agent_file = "/tmp/wolf.agent"
    if File.exist?(agent_file)
      puts "Previous agent file found. Exiting"
      exit
    else
      f = File.new(agent_file, "w+")
      f.write(agent["id"])
    end

  end

  def store_agent(agent)

#    uri = URI.parse(ENV["DEN_ADDR"]+'/store_agent')
#    response = Net::HTTP.post_form(uri, {"WOLF_KEY" => ENV["WOLF_KEY"], "USERNAME" => username, "COOKIES" => cookies})

    f = File.new(@agents_file, "a+")
    f.write(agent.to_json+"\n")
  end

  def quit
    @driver.quit
  end

  def lurk(subreddit = nil)
    # list of subreddits to lurk
    subreddits = subreddit || ["entrepreneur/", "startups/", "finance/", "artificial/", "machinelearning/", "robotics/"].shuffle
    # subreddit pages
    pages = ["top/", "new/", "rising/", "controversial/"].shuffle

    time = ["hour", "week", "month", "year", "all"].shuffle

    url = "https://www.reddit.com/r/"

    subreddits.each do |subreddit|
      pages.each do |page|
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

  def vote(link, upvote = true)
    # parse subreddit
    parsed_link = reddit_link_parse(link)
    # search through pages for link
    subreddit_page = "https://www.reddit.com/r/"+parsed_link["subreddit"]
    puts "Looking for: " + link
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
end

@wolf = Wolf.new
#agents = @wolf.load_agents
#@driver = @wolf.connect
#@wolf.create_user
#@wolf.become_agent(agents.sample)
#link = "https://www.reddit.com/r/InternetIsBeautiful/comments/412si3/drinkify_is_a_website_that_simply_put_tells_you/"
#@wolf.vote(link, true)
#@wolf.lurk
#@wolf.quit

def at_exit
  pid_file = "/tmp/wolf.pid"
  current_pid = Process.pid
  running_pid = File.read(pid_file)
  if current_pid == running_pid
    File.destroy(pid_file)
  end
end