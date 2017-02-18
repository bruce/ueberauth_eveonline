defmodule Ueberauth.Strategy.EveOnline.OAuth do
  @moduledoc """
  An implementation of OAuth2 for eveonline.

  To add your `client_id` and `client_secret` include these values in your configuration.

      config :ueberauth, Ueberauth.Strategy.EveOnline.OAuth,
        client_id: System.get_env("EVEONLINE_CLIENT_ID"),
        client_secret: System.get_env("EVEONLINE_CLIENT_SECRET")
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://developers.eveonline.com",
    authorize_url: "https://login.eveonline.com/oauth/authorize",
    token_url: "https://login.eveonline.com/oauth/token",
  ]

  @doc """
  Construct a client for requests to EveOnline.

  Optionally include any OAuth2 options here to be merged with the defaults.

      Ueberauth.Strategy.EveOnline.OAuth.client(redirect_uri: "http://localhost:4000/auth/eveonline/callback")

  This will be setup automatically for you in `Ueberauth.Strategy.EveOnline`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.EveOnline.OAuth)
    client_opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    OAuth2.Client.new(client_opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_token!(params \\ [], options \\ []) do
    headers        = Keyword.get(options, :headers, [])
    options        = Keyword.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, [])
    client         = OAuth2.Client.get_token!(client(client_options), params, headers, options)
    client.token
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
