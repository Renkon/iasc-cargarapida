defmodule Router do
  use Plug.Router

  plug :match
  plug :set_default_content_type
  plug :dispatch

  get "/ping" do
    send_resp(conn, 200, "pong")
  end

  post "/signup" do
    with {:ok, %{"username" => username, "password" => password}} <- parse_json_body(conn) do
      case CargaRapida.UserSupervisor.create(username, password) do
        {:ok, _pid} ->
          send_resp(conn, 201, Jason.encode!(%{result: "User created"}))
        {:error, {:already_started, _pid}} ->
          send_resp(conn, 409, Jason.encode!(%{error: "User already exists"}))
        {:error, reason} ->
          send_resp(conn, 500, Jason.encode!(%{error: inspect(reason)}))
      end
    else
      _ -> send_resp(conn, 400, Jason.encode!(%{error: "Invalid JSON"}))
    end
  end

  post "/login" do
    with {:ok, %{"username" => username, "password" => password}} <- parse_json_body(conn) do
      case Horde.Registry.lookup(CargaRapida.UserRegistry, username) do
        [{pid, _value}] ->
          case GenServer.call(pid, :get_password) do
            ^password -> send_resp(conn, 200, Jason.encode!(%{user: username}))
            _ -> send_resp(conn, 401, Jason.encode!(%{error: "Invalid password"}))
          end
        [] ->
          send_resp(conn, 401, Jason.encode!(%{error: "Invalid username"}))
      end
    else
      _ -> send_resp(conn, 400, Jason.encode!(%{error: "Invalid JSON"}))
    end
  end

  post "/timeslot" do
    with {:ok, %{
            "types_with_power" => types_with_power,
            "datetime" => datetime_str,
            "station" => station,
            "duration_min" => duration_min
          }} <- parse_json_body(conn) do
      types_with_power =
        Enum.map(types_with_power, fn %{"type" => type, "power" => power} -> {String.to_atom(type), power} end)

      result = CargaRapida.StationManager.create_timeslot(types_with_power, datetime_str, String.to_atom(station), duration_min)
      send_resp(conn, 201, Jason.encode!(%{result: result}))
    else
      _ -> send_resp(conn, 400, Jason.encode!(%{error: "Invalid JSON"}))
    end

    #TODO: trigger existing notifications
  end

  get "/reservation" do
    send_resp(conn, 200, "pong")#
    #TODO: is this needed or just the alerts is ok?
  end

  post "/reservation" do
    send_resp(conn, 200, "pong")#
    #TODO: assign user to charging point
  end

  post "/alert" do
    send_resp(conn, 200, "pong")#
    #TODO
  end

  match _ do
    send_resp(conn, 404, Jason.encode!(%{error: "Not found"}))
  end

  defp set_default_content_type(conn, _opts) do
    Plug.Conn.put_resp_content_type(conn, "application/json")
  end

  defp parse_json_body(conn) do
    with {:ok, body, _conn} <- Plug.Conn.read_body(conn),
         {:ok, params} <- Jason.decode(body) do
      {:ok, params}
    else
      _ -> :error
    end
  end
end
