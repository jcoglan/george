require 'base64'
require 'oauth'
require 'rack'
require 'webrick'

class George
  class OAuthClient

    DEFAULT_COMMANDS = {
      /(mingw|mswin|windows|cygwin)/i => ['cmd', '/C', 'start', '/b'],
      /(darwin|mac os)/i              => ['open'],
      /(linux|bsd|aix|solaris)/i      => ['xdg-open']
    }

    GIF_PATH = File.join(TEMPLATE_PATH, 'thumbsup.gif')

    RESPONSE_BODY = <<-HTML
<!doctype html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>Tea is on its way!</title>
    <style type="text/css">
      body {
        background: #fff;
        color: #666;
        font: 18px/1.5 FreeSans, Helvetica, Arial, sans-serif;
      }

      section {
        width: 400px;
        margin: 40px auto;
      }

      img {
        display: block;
        width: 360px;
        border: 10px solid #eee;
      }

      h1 {
        font-weight: normal;
        font-size: 2.4em;
        margin: 0.6em 0 0.4em;
      }
    </style>
  </head>
  <body>

    <section>
      <img alt="Thumbs up!" src="data:image/gif;base64,#{ Base64.encode64(File.read(GIF_PATH)).gsub(/[\s\n\r\t]/, '') }">

      <h1>Tea is on its way!</h1>

      <p>You&rsquo;re authorized to post to Twitter. Close this window and
        return to your terminal.</p>
    </section>

  </body>
</html>
    HTML

    def initialize(config)
      @config = config
      @client = OAuth::Consumer.new(
                  config.consumer_key,
                  config.consumer_secret, 
                  :site => config.provider_site
                )
    end

    def boot
      @server_thread = Thread.new do
        handler = Rack::Handler.get('webrick')
        handler.run(self, :Port => DEFAULT_PORT,
                          :AccessLog => [], 
                          :Logger => WEBrick::Log::new(nil, 0))
      end
    end

    def authorize_url
      @request_token.authorize_url(:oauth_callback => @config.callback_url)
    end

    def get_oauth_credentials
      @request_token = @client.get_request_token(:oauth_callback => @config.callback_url)
      launch_browser(authorize_url)
      sleep 1 until @oauth_credentials
      @oauth_credentials
    end

    def launch_browser(url)
      os   = RbConfig::CONFIG['host_os']
      key  = DEFAULT_COMMANDS.keys.find { |key| os =~ key }
      argv = DEFAULT_COMMANDS[key] + [url]

      @browser = ChildProcess.build(*argv)
      @browser.start
    end

    def call(env)
      return [404, {}, []] unless env['PATH_INFO'] == CALLBACK_PATH

      params = Rack::Request.new(env).params
      @access_token = @request_token.get_access_token(:oauth_verifier => params['oauth_verifier'])

      @oauth_credentials = {
        'token'  => @access_token.token,
        'secret' => @access_token.secret
      }

      [200, {'Content-Type' => 'text/html'}, [RESPONSE_BODY]]
    end

  end
end

