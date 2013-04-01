require 'childprocess'
require 'erb'
require 'json'
require 'twitter'
require 'yaml'

class George
  ROOT          = File.expand_path('../..', __FILE__)
  LIB           = ROOT + '/lib/george'
  CONFIG_PATH   = ROOT + '/config/twitter.yml'
  ANNA_VIM      = ROOT + '/config/anna.vim'
  TEMPLATE_PATH = ROOT + '/templates'

  CALLBACK_PATH = '/authenticate'
  DEFAULT_PORT  = 4180
  DOTFILE_PATH  = File.expand_path('~/.georgerc')
  SCRATCH_PATH  = File.expand_path('~/.GEORGE_TWEET')

  autoload :Config,      LIB + '/config'
  autoload :OAuthClient, LIB + '/oauth_client'

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

  def install(*args)
    client = OAuthClient.new(config)
    client.boot
    credentials = client.get_oauth_credentials
    File.open(DOTFILE_PATH, 'w') { |f| f.write(JSON.dump(credentials)) }
  end

  def vim(*args)
    File.open(SCRATCH_PATH, 'w') do |f|
      f.write "# Compose your tweet in George's favourite editor!\n"
    end
    vim = ChildProcess.build('vim', '-u', ANNA_VIM, SCRATCH_PATH)
    vim.io.inherit!
    vim.start
    sleep 0.01 until vim.exited?
    message = File.read(SCRATCH_PATH).split("\n").delete_if { |l| l =~ /^\s*#/ }.join("\n")

    post_to_twitter(message)
  ensure
    File.unlink(SCRATCH_PATH)
  end

  Dir.entries(TEMPLATE_PATH).grep(/\.yml$/).each do |n|
    undef_method File.basename(n, '.yml') rescue nil
  end

  def method_missing(name, *args)
    template_path = File.join(TEMPLATE_PATH, "#{name}.yml")
    raise "Not a valid command: `george #{name}`" unless File.file?(template_path)

    templates = YAML.load_file(template_path)
    thing     = args.first
    messages  = (templates['custom'][thing] || []) + templates['generic']
    template  = messages[rand(messages.size)]
    message   = ERB.new(template).result(binding)

    post_to_twitter(message)
  end

  def post_to_twitter(message)
    message.strip!
    return if message == ''
    tweet = "@#{twitter_username} #{message}"
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

