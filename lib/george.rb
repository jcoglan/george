require 'childprocess'
require 'erb'
require 'json'
require 'oauth'
require 'rack'
require 'twitter'
require 'webrick'

class George
  ROOT = File.expand_path('..', __FILE__)

  CALLBACK_PATH = '/authenticate'
  COMMANDS      = %w[install make]
  CONFIG_PATH   = ROOT + '/../config/twitter.yml'
  DEFAULT_PORT  = 4180
  DOTFILE_PATH  = File.expand_path('~/.georgerc')

  autoload :Config,      ROOT + '/george/config'
  autoload :Make  ,      ROOT + '/george/make'
  autoload :OAuthClient, ROOT + '/george/oauth_client'

  def self.run(argv)
    new.run(argv)
  end

  def config
    @config ||= Config.new(CONFIG_PATH)
  end

  def run(argv)
    command = argv.first
    unless COMMANDS.include?(command)
      $stderr.puts "Not a valid command: #{command}"
      exit 1
    end
    __send__(command, *argv[1..-1])
    exit 0
  rescue => e
    $stderr.puts(e.message)
    exit 1
  end

  def install
    client = OAuthClient.new(config)
    client.boot
    credentials = client.get_oauth_credentials
    File.open(DOTFILE_PATH, 'w') { |f| f.write(JSON.dump(credentials)) }
  end

  def make(beverage)
    tweet = "@#{twitter_username} #{Make.message(beverage)}"
    twitter.update(tweet)
  end

  def twitter
    unless File.file?(DOTFILE_PATH)
      raise "Please run `george install` to authenticate with Twitter"
    end

    credentials = JSON.parse(File.read(DOTFILE_PATH))
    Twitter::Client.new(
      :consumer_key       => config.consumer_key,
      :consumer_secret    => config.consumer_secret,
      :oauth_token        => credentials['token'],
      :oauth_token_secret => credentials['secret']
    )
  end

  def twitter_username
    ENV['GEORGE_USERNAME'] || config.twitter_username
  end
end

