defmodule CargaRapida.StationManager do
  def create_timeslot(types_with_power, start_time_str, station, duration_min) do
    {:ok, start_time, _offset} = DateTime.from_iso8601(start_time_str)
    now = DateTime.utc_now()
    death_time = DateTime.add(now, round(duration_min * 60), :second)

    Enum.map(types_with_power, fn {type, kw} ->
      id = UUID.uuid4()

      case CargaRapida.ChargingPointSupervisor.create(id, start_time, station, death_time, type, kw) do
        {:ok, _pid} ->
          payload = %{
            id: id,
            type: type,
            power: kw,
            start_time: DateTime.to_iso8601(start_time),
            station: station,
            death_time: DateTime.to_iso8601(death_time)
          }

          notify_alerted_users(start_time, type, kw, station, payload)

          Map.put(payload, :status, "ok")

        {:error, {:already_started, _pid}} ->
          %{
            status: "error",
            id: id,
            type: type,
            power: kw,
            code: "already_exists",
            message: "A charging point with this ID already exists"
          }

        {:error, reason} ->
          %{
            status: "error",
            id: id,
            type: type,
            power: kw,
            code: inspect(reason),
            message: "Failed to create charging point due to an internal error."
          }
      end
    end)
  end

  def get_charger_types do
    [:CCS, :CHAdeMO, :Tipo2, :Tipo1, :Tesla]
  end

  def get_stations do
    [:Campus, :Medrano, :Obelisco]
  end

  def notify_alerted_users(start_time, type, power, station, payload) do
    alerts = CargaRapida.AlertAgent.matching_alerts(start_time, type, power, station)

    Enum.each(alerts, fn %Alert{user_id: user_id} ->
      notify_user(user_id, payload)
    end)
  end

  def notify_matching_existing_charging_points(alert, user_id) do
    charging_points = CargaRapida.ChargingPointAgent.matching_charging_points(alert)

    Enum.each(charging_points, fn %ChargingPoint{
      id: id,
      type: type,
      power: power,
      start_time: start_time,
      station: station,
      end_time: end_time
    } ->
      payload = %{
        id: id,
        type: type,
        power: power,
        start_time: start_time,
        station: station,
        end_time: end_time
      }

      notify_user(user_id, payload)
    end)
  end

  defp notify_user(user_id, payload) do
    case Horde.Registry.lookup(CargaRapida.UserRegistry, user_id) do
      [{pid, _}] ->
        GenServer.cast(pid, {:send_ws, Jason.encode!(%{type: "alert", data: payload})})

      _ -> :ok
    end
  end
end
