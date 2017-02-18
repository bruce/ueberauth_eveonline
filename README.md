# Überauth EveOnline

> EveOnline OAuth2 strategy for Überauth.

## Installation

1. Setup your application at the [EVE Developer site](https://developers.eveonline.com)

1. Add `:ueberauth_eveonline` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_eveonline, "~> 0.2"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_eveonline]]
    end
    ```

1. Add EveOnline to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        eveonline: {Ueberauth.Strategy.EveOnline, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.EveOnline.OAuth,
      client_id: System.get_env("EVEONLINE_CLIENT_ID"),
      client_secret: System.get_env("EVEONLINE_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      pipeline :browser do
        plug Ueberauth
        ...
      end
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

## Calling

Depending on the configured url you can initial the request through:

    /auth/eveonline

Or with options:

    /auth/eveonline?scope=characterAccountRead+publicData

By default the requested scope is "characterAccountRead publicData". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    eveonline: {Ueberauth.Strategy.EveOnline, [default_scope: "characterAccountRead publicData characterFittingsRead"]}
  ]
```

## License

Please see [LICENSE](https://github.com/bruce/ueberauth_eveonline/blob/master/LICENSE) for licensing details.
