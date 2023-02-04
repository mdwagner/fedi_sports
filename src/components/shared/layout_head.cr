class Shared::LayoutHead < BaseComponent
  needs page_title : String

  def render
    head do
      utf8_charset
      title "My App - #{@page_title}"
      app_css
      app_js
      csrf_meta_tags
      responsive_meta_tag

      # Used only in development when running `lucky watch`.
      # Will reload browser whenever files change.
      # See [docs]()
      live_reload_connect_tag
    end
  end

  private def app_css
    tag "style", media: "screen" do
      raw <<-CSS
      p {
        color: #26b72b;
      }
      CSS
    end
  end

  private def app_js
    tag "script", defer: "true" do
      raw <<-JS
      //import Alpine from "alpinejs";
      //window.Alpine = Alpine;
      //Alpine.start();
      console.log("hello world!");
      JS
    end
  end
end
