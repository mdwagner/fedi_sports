class WellKnown::WebFinger < ApiAction
  include Api::Auth::SkipRequireAuthToken
  include Lucky::SkipRouteStyleCheck

  param resource : String

  get "/.well-known/webfinger" do
    response.headers["Access-Control-Allow-Origin"] = "*"

    _, account = resource.split("acct:")

    raise Lucky::RouteNotFoundError.new(context) unless account

    account = account.not_nil!

    username, domain = account.split("@")

    json({
      "subject" => resource,
      "links" => [
        {
          "rel" => "http://webfinger.net/rel/avatar",
          "href" => "http://www.example.com/~bob/bob.jpg",
        },
        {
          "rel" => "http://webfinger.net/rel/profile-page",
          "href" => "http://www.example.com/~bob/",
        },
      ],
    })
  end
end
