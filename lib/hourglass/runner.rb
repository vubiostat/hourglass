module Hourglass
  class Runner
    def initialize
      Database.migrate!
      if start_server
        start_browser
      end
    end

    def start_server
      handler = Rack::Handler.get('mongrel')
      settings = Application.settings

      @web_server = Mongrel::HttpServer.new(settings.bind, settings.port, 950, 0, 60)
      @web_server.register('/', handler.new(Application))
      success = false
      begin
        @web_thread = @web_server.run
        success = true
      rescue Errno::EADDRINUSE => e
        puts "Can't start web server, port already in use. Aborting..."
      end
      success
    end

    def start_browser
      display = Swt::Widgets::Display.new
      shell = Swt::Widgets::Shell.new(display)
      shell.text = "Hourglass"
      shell.set_size(500, 300)
      layout = Swt::Layout::FillLayout.new
      shell.layout = layout
      browser = Swt::Browser.new(shell, Swt::SWT::WEBKIT)
      shell.open
      browser.set_url("http://localhost:4567")
      while !shell.disposed?
        if !display.read_and_dispatch
          display.sleep
        end
      end
      display.dispose
    end
  end
end
