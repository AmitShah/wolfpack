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
  end

  def write_agent(agent)
    f = File.new(@agents_file, "a+")
    f.write(agent.to_json+"\n")
  end

  def quit
    @driver.quit
  end

  def zombie_mode
    # list of subreddits to lurk
    subreddits = ["entrepreneur/", "startups/", "finance/", "artificial/", "machinelearning/", "robotics/"].shuffle
    # subreddit pages
    pages = ["top", "new", "rising", "controversial"].shuffle

    time = ["hour", "week", "month", "year", "all"].shuffle

    url = "https://www.reddit.com/r/"

    subreddits.each do |subreddit|
      pages.each do |page|
        main_page = url + subreddit + page
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

  def upvote
    # get upvote link
    # get subreddit
    # search through pages for link
    # once the link is found, click it
    # go through and upvote all the comments
  end

  def downvote
    # find account
    # downvote
  end

end

@wolf = Wolf.new
agents = @wolf.load_agents
@driver = @wolf.connect
#@wolf.create_user
@wolf.become_agent(agents.sample)
@wolf.zombie_mode
#@wolf.quit