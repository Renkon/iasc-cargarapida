defmodule Router do
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug :match
  plug :set_default_content_type
  plug :dispatch

  get "/ping" do
    send_resp(conn, 200, "pong")
  end

  post "/signup" do
    with %{"username" => username, "password" => password} <- conn.params do
      case CargaRapida.UserSupervisor.create(username, password) do
        {:ok, _pid} ->
          send_resp(conn, 201, Jason.encode!(%{result: "User created"}))
        {:error, {:already_started, _pid}} ->
          send_resp(conn, 409, Jason.encode!(%{error: "User already exists"}))
        {:error, reason} ->
          send_resp(conn, 500, Jason.encode!(%{error: inspect(reason)}))
      end
    else
      _ -> send_resp(conn, 400, Jason.encode!(%{error: "Invalid JSON: missing username or password"}))
    end
  end

  post "/login" do
    with %{"username" => username, "password" => password} <- conn.params do
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
      _ -> send_resp(conn, 400, Jason.encode!(%{error: "Invalid JSON: missing username or password"}))
    end
  end

  post "/timeslot" do
    with %{
          "types_with_power" => types_with_power,
          "datetime" => datetime_str,
          "station" => station,
          "duration_min" => duration_min
        } <- conn.params,
        # Validate station exists
        {:station_exists, true} <- {:station_exists, Enum.member?(CargaRapida.StationManager.get_stations(), String.to_atom(station))},
        # Validate all types are valid
        valid_types = CargaRapida.StationManager.get_charger_types(),
        {:types_valid, true} <- {:types_valid, Enum.all?(types_with_power, fn %{"type" => type} -> String.to_atom(type) in valid_types end)}
    do
      types_with_power =
        Enum.map(types_with_power, fn %{"type" => type, "power" => power} -> {String.to_atom(type), power} end)

      result = CargaRapida.StationManager.create_timeslot(types_with_power, datetime_str, String.to_atom(station), duration_min)
      send_resp(conn, 201, Jason.encode!(%{result: result}))
    else
      {:station_exists, false} ->
        send_resp(conn, 404, Jason.encode!(%{error: "Station does not exist"}))
      {:types_valid, false} ->
        send_resp(conn, 400, Jason.encode!(%{error: "Invalid charger type"}))
      _ ->
        send_resp(conn, 400, Jason.encode!(%{error: "Invalid or incomplete JSON"}))
    end
  end

  get "/matching_timeslots" do
    user_id = conn.params["user_id"]

    if user_id do
      case CargaRapida.UserAgent.get_entry(user_id) do
        nil ->
          send_resp(conn, 404, Jason.encode!(%{error: "User does not exist"}))
        _user ->
          alerts = CargaRapida.AlertAgent.user_alerts(user_id)
          results = CargaRapida.ChargingPointAgent.matching_charging_points_multiple(alerts)
          send_resp(conn, 200, Jason.encode!(results))
      end
    else
      send_resp(conn, 400, Jason.encode!(%{error: "Missing user_id query parameter"}))
    end
  end

  get "/assigned_timeslots" do
    user_id = conn.params["user_id"]

    if user_id do
      case CargaRapida.UserAgent.get_entry(user_id) do
        nil ->
          send_resp(conn, 404, Jason.encode!(%{error: "User does not exist"}))
        _user ->
          results = CargaRapida.ChargingPointAgent.get_charging_points_by_user(user_id)
          send_resp(conn, 200, Jason.encode!(results))
      end
    else
      send_resp(conn, 400, Jason.encode!(%{error: "Missing user_id query parameter"}))
    end
  end

  post "/reservation" do
  with %{"user_id" => user_id, "charging_point_id" => charging_point_id} <- conn.params,
       # Validate user exists
       {:user_exists, true} <- {:user_exists, not is_nil(CargaRapida.UserAgent.get_entry(user_id))},
       :ok <- CargaRapida.ChargingPointSupervisor.assign_user(charging_point_id, user_id)
  do
    send_resp(conn, 200, Jason.encode!(%{status: "assigned"}))
  else
    {:user_exists, false} ->
      send_resp(conn, 404, Jason.encode!(%{error: "User does not exist"}))
    {:error, :already_reserved, existing_user} ->
      send_resp(conn, 409, Jason.encode!(%{error: "already_reserved", by: existing_user}))
    {:error, :invalid_charging_point_id} ->
      send_resp(conn, 404, Jason.encode!(%{error: "Invalid charging point ID"}))
    _ ->
      send_resp(conn, 400, Jason.encode!(%{error: "Invalid JSON or request"}))
  end
end

  post "/alert" do
    with %{
          "user_id" => user_id,
          "start_time" => start_time_str,
          "end_time" => end_time_str,
          "type" => type,
          "min_power" => min_power,
          "station" => station
        } <- conn.params,
        # Validate user exists
        {:user_exists, true} <- {:user_exists, not is_nil(CargaRapida.UserAgent.get_entry(user_id))},
        # Validate station exists
        {:station_exists, true} <- {:station_exists, Enum.member?(CargaRapida.StationManager.get_stations(), String.to_atom(station))},
        result <- CargaRapida.AlertSupervisor.create_alert(user_id, type, min_power, station, start_time_str, end_time_str)
    do
      case result do
        {:ok, alert_id} ->
          send_resp(conn, 201, Jason.encode!(%{id: alert_id}))
        {:error, reason} ->
          send_resp(conn, 500, Jason.encode!(%{error: inspect(reason)}))
      end
    else
      {:user_exists, false} ->
        send_resp(conn, 404, Jason.encode!(%{error: "User does not exist"}))
      {:station_exists, false} ->
        send_resp(conn, 404, Jason.encode!(%{error: "Station does not exist"}))
      _ ->
        send_resp(conn, 400, Jason.encode!(%{error: "Invalid or incomplete JSON"}))
    end
  end

  get "/stations" do
    stations = CargaRapida.StationManager.get_stations()
    send_resp(conn, 200, Jason.encode!(stations))
  end

  get "/charger_types" do
    charger_types = CargaRapida.StationManager.get_charger_types()
    send_resp(conn, 200, Jason.encode!(charger_types))
  end

  match _ do
    send_resp(conn, 404, Jason.encode!(%{error: "Not found"}))
  end

  defp set_default_content_type(conn, _opts) do
    Plug.Conn.put_resp_content_type(conn, "application/json")
  end
end
