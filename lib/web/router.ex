defmodule Router do
  use Plug.Router

  plug :match
  plug :set_default_content_type
  plug :dispatch

  get "/ping" do
    send_resp(conn, 200, "pong")
  end

  post "/signup" do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    case Jason.decode(body) do
      {:ok, %{"username" => username, "password" => password}} ->
        case CargaRapida.UserSupervisor.create(username, password) do
          {:ok, _pid} ->
            send_resp(conn, 201, Jason.encode!(%{result: "User created"}))
          {:error, {:already_started, _pid}} ->
            send_resp(conn, 409, Jason.encode!(%{error: "User already exists"}))
          {:error, reason} ->
            send_resp(conn, 500, Jason.encode!(%{error: inspect(reason)}))
        end
      {:error, _} ->
        send_resp(conn, 400, Jason.encode!(%{error: "Invalid JSON"}))
    end
  end

  post "/login" do
  {:ok, body, _conn} = Plug.Conn.read_body(conn)
  case Jason.decode(body) do
    {:ok, %{"username" => username, "password" => password}} ->
      case Horde.Registry.lookup(CargaRapida.UserRegistry, username) do
        [{pid, _value}] ->
          # Ask the user process for its password
          case GenServer.call(pid, :get_password) do
            ^password ->
              send_resp(conn, 200, Jason.encode!(%{user: username}))
            _ ->
              send_resp(conn, 401, Jason.encode!(%{error: "Invalid password"}))
          end
        [] ->
          send_resp(conn, 401, Jason.encode!(%{error: "Invalid username"}))
      end
    {:error, _} ->
      send_resp(conn, 400, Jason.encode!(%{error: "Invalid JSON"}))
    end
  end

  match _ do
    send_resp(conn, 404, Jason.encode!(%{error: "Not found"}))
  end

  defp set_default_content_type(conn, _opts) do
    Plug.Conn.put_resp_content_type(conn, "application/json")
  end
end
