class Shared::LayoutHead < BaseComponent
  needs page_title : String

  def render
    head do
      utf8_charset
      title @page_title

      tailwind_css
      alpine_js
      htmx_js

      app_css
      app_js

      csrf_meta_tags
      responsive_meta_tag

      live_reload_connect_tag
    end
  end

  private def tailwind_css
    tag "script",
      src: "https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio,line-clamp"
  end

  private def alpine_js
    tag "script",
      src: "https://unpkg.com/alpinejs@3.11.1/dist/cdn.min.js",
      defer: "true"
  end

  private def htmx_js
    tag "script",
      src: "https://unpkg.com/htmx.org@1.8.5",
      integrity: "sha384-7aHh9lqPYGYZ7sTHvzP1t3BAfLhYSTy9ArHdP3Xsr9/3TlGurYgcPBoFmXX2TX/w",
      crossorigin: "anonymous"
  end

  private def app_css
    tag "style", media: "screen" do
      raw <<-CSS
      [x-cloak] {
        display: none !important;
      }
      CSS
    end
  end

  private def app_js
    tag "script", defer: "true"
  end
end
