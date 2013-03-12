require 'childprocess'
require 'oauth'
require 'rack'
require 'twitter'
require 'webrick'
require 'yaml'

class George
  CALLBACK_PATH       = '/authenticate'
  COMMANDS            = %w[install]
  DEFAULT_PORT        = 4180
  RC_PATH             = File.expand_path('~/.georgerc')
  ROOT                = File.expand_path('..', __FILE__)
  TWITTER_CONFIG_PATH = ROOT + '/../config/twitter.yml'

  autoload :Config,      ROOT + '/george/config'
  autoload :OAuthClient, ROOT + '/george/oauth_client'

  def self.run(argv)
    new.run(argv)
  end

  def config
    @config ||= Config.new(TWITTER_CONFIG_PATH)
  end

  def run(argv)
    command = argv.first
    unless COMMANDS.include?(command)
      $stderr.puts "Not a valid command: #{command}"
      exit 1
    end
    __send__(command)
  end

  def install
    client = OAuthClient.new(config)
    client.boot
    credentials = client.get_oauth_credentials
    File.open(RC_PATH, 'w') { |f| f.write(YAML.dump(credentials)) }
    exit 0
  end
end

