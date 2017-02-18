defmodule Ueberauth.Strategy.EveOnline do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with EveOnline.

  ### Setup

  Create an application in EveOnline for you to use.

  Register a new application at: [your EVE developer page](https://developers.eveonline.com) and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth:

      config :ueberauth, Ueberauth,
        providers: [
          eveonline: { Ueberauth.Strategy.EveOnline, [] }
        ]

  Then include the configuration for eveonline.

      config :ueberauth, Ueberauth.Strategy.EveOnline.OAuth,
        client_id: System.get_env("EVEONLINE_CLIENT_ID"),
        client_secret: System.get_env("EVEONLINE_CLIENT_SECRET")

  If you haven't already, create a pipeline and setup routes for your callback handler:

      pipeline :auth do
        Ueberauth.plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end


  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct:

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you register your provider.

  To set the `uid_field`:

      config :ueberauth, Ueberauth,
        providers: [
          eveonline: { Ueberauth.Strategy.EveOnline, [uid_field: :email] }
        ]

  Default is `:login`.

  To set the default 'scopes' (permissions):

      config :ueberauth, Ueberauth,
        providers: [
          eveonline: { Ueberauth.Strategy.EveOnline, [default_scope: "user,public_repo"] }
        ]

  Default is "user,public_repo"
  """
  use Ueberauth.Strategy, uid_field: :login,
                          default_scope: "characterAccountRead,publicData",
                          oauth2_module: Ueberauth.Strategy.EveOnline.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the EVE Online authentication page.

  To customize the scope (permissions) that are requested by eveonline include them as part of your url:

      "/auth/eveonline?scope=characterAccountRead,publicData,characterFittingsRead"

  You can also include a `state` param that eveonline will return to you.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [redirect_uri: callback_url(conn), scope: scopes]

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from EveOnline. When there is a failure from EveOnline the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from EveOnline is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code]])

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw EveOnline response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:eveonline_user, nil)
    |> put_private(:eveonline_token, nil)
  end

  @doc """
  Fetches the uid field from the EveOnline response. This defaults to the option `uid_field` which in-turn defaults to `login`
  """
  def uid(conn) do
    user =
      conn
      |> option(:uid_field)
      |> to_string
    conn.private.eveonline_user[user]
  end

  @doc """
  Includes the credentials from the EveOnline response.
  """
  def credentials(conn) do
    token        = conn.private.eveonline_token
    scope_string = (token.other_params["scope"] || "")
    scopes       = String.split(scope_string, ",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.eveonline_user

    %Info{

    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the EveOnline callback.
  """
  def extra(conn) do
    %Extra {
      raw_info: %{
        token: conn.private.eveonline_token,
        user: conn.private.eveonline_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn
    |> put_private(:eveonline_token, token)
    |> put_private(:eveonline_user, %{})
    # Will be better with Elixir 1.3 with/else
    # case Ueberauth.Strategy.EveOnline.OAuth.get(token, "/user") do
    #   {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
    #     set_errors!(conn, [error("token", "unauthorized")])
    #   {:ok, %OAuth2.Response{status_code: status_code, body: user}} when status_code in 200..399 ->
    #     case Ueberauth.Strategy.EveOnline.OAuth.get(token, "/user/emails") do
    #       {:ok, %OAuth2.Response{status_code: status_code, body: emails}} when status_code in 200..399 ->
    #         user = Map.put user, "emails", emails
    #         put_private(conn, :eveonline_user, user)
    #       {:error, _} -> # Continue on as before
    #         put_private(conn, :eveonline_user, user)
    #     end
    #   {:error, %OAuth2.Error{reason: reason}} ->
    #     set_errors!(conn, [error("OAuth2", reason)])
    # end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
