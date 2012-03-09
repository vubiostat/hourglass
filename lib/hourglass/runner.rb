module Hourglass
  class Runner
    import org.eclipse.swt.events.ShellListener
    import org.eclipse.swt.browser.OpenWindowListener
    import org.eclipse.swt.browser.CloseWindowListener
    import org.eclipse.swt.browser.VisibilityWindowListener
    import org.eclipse.swt.browser.TitleListener
    import org.eclipse.swt.browser.TitleEvent
    import org.eclipse.swt.browser.ProgressListener

    class ShellWrapper < Delegator
      include ShellListener

      attr_reader :shell, :frame_x, :frame_y
      alias :__getobj__ :shell

      def initialize(*args)
        @shell = Swt::Widgets::Shell.new(*args)
        @shell.set_size(500, 400)
        @shell.layout = Swt::Layout::FillLayout.new
        @shell.add_shell_listener(self)
        super(@shell)
      end

      # To satisfy ShellListener
      def shellIconified(event); end
      def shellDeiconified(event); end
      def shellDeactivated(event); end
      def shellClosed(event); end

      def shellActivated(event)
        client_area = @shell.client_area
        @frame_x = @shell.size.x - client_area.width
        @frame_y = @shell.size.y - client_area.height
      end

      def set_client_area_size(width, height)
        @shell.set_size(width + @frame_x, height + @frame_y)
      end
    end

    class BrowserWrapper < Delegator
      include OpenWindowListener
      include CloseWindowListener
      include VisibilityWindowListener
      include TitleListener
      include ProgressListener

      attr_reader :browser
      alias :__getobj__ :browser

      def initialize(shell_wrapper)
        @shell_wrapper = shell_wrapper
        @browser = Swt::Browser.new(shell_wrapper.shell, Swt::SWT::WEBKIT)
        @browser.add_open_window_listener(self)
        @browser.add_close_window_listener(self)
        @browser.add_visibility_window_listener(self)
        @browser.add_title_listener(self)
        @browser.add_progress_listener(self)
        super(@browser)
      end

      def open(event)
        # For OpenWindowListener
        # pop-up support
        if event.required
          popup_shell = ShellWrapper.new(@shell_wrapper.display)
          popup_browser = BrowserWrapper.new(popup_shell)
          event.browser = popup_browser.browser
        else
          puts "Not required!"
        end
      end

      def close(event)
        # For CloseWindowListener
        @shell_wrapper.close
      end

      def hide(event)
        # For VisibilityWindowListener
        @shell_wrapper.visible = false
      end

      def show(event)
        # For VisibilityWindowListener
        @shell_wrapper.location = event.location if event.location
        @shell_wrapper.open
      end

      def changed(event)
        # For TitleListener and ProgressListener
        case event
        when TitleEvent
          @shell_wrapper.set_text(event.title)
        end
      end

      def completed(event)
        # For ProgressListener
        #@shell_wrapper.set_client_area_size(outer_body_width, outer_body_height);
      end

      def outer_body_width
        browser.evaluate("return $('body').outerWidth(true);")
      end

      def outer_body_height
        browser.evaluate("return $('body').outerHeight(true);")
      end
    end

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
      shell_wrapper = ShellWrapper.new(display)
      browser_wrapper = BrowserWrapper.new(shell_wrapper)
      browser_wrapper.set_url("http://localhost:4567")
      shell_wrapper.open
      while !shell_wrapper.disposed?
        if !display.read_and_dispatch
          display.sleep
        end
      end
      display.dispose
    end
  end
end
