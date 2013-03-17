require 'childprocess'
require 'erb'
require 'json'
require 'oauth'
require 'rack'
require 'twitter'
require 'webrick'
require 'yaml'

class George
  ROOT          = File.expand_path('..', __FILE__)
  CONFIG_PATH   = File.expand_path('../../config/twitter.yml', __FILE__)
  TEMPLATE_PATH = File.expand_path('../../templates', __FILE__)

  CALLBACK_PATH = '/authenticate'
  COMMANDS      = %w[install make]
  DEFAULT_PORT  = 4180
  DOTFILE_PATH  = File.expand_path('~/.georgerc')

  autoload :Config,      ROOT + '/george/config'
  autoload :OAuthClient, ROOT + '/george/oauth_client'

  def self.run(argv)
    new.run(argv)
  end

  def config
    @config ||= Config.new(CONFIG_PATH)
  end

  def run(argv)
    command = argv.first
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

  def method_missing(name, *args)
    template_path = File.join(TEMPLATE_PATH, "#{name}.yml")
    raise "Not a valid command: `george #{name}`" unless File.file?(template_path)

    templates = YAML.load_file(template_path)
    thing     = args.first
    messages  = (templates['custom'][thing] || []) + templates['generic']
    template  = messages[rand(messages.size)]
    message   = ERB.new(template).result(binding)

    post_to_twitter("@#{twitter_username} #{message}")
  end

  def post_to_twitter(tweet)
    if ENV['DEBUG']
      puts tweet
    else
      twitter.update(tweet)
    end
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

