defmodule CargaRapida.StationManager do
  def create_timeslot(types_with_power, datetime_str, station, duration_min) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(datetime_str)
    offer_endtime = DateTime.add(DateTime.utc_now(), round(duration_min * 60), :second)

    Enum.map(types_with_power, fn {type, kw} ->
      id = UUID.uuid4()

      case CargaRapida.ChargingPointSupervisor.create(id, datetime, station, offer_endtime, type, kw) do
        {:ok, _pid} ->
          payload = %{
            id: id,
            type: type,
            power: kw,
            datetime: datetime_str,
            station: station,
            duration_min: duration_min,
            offer_endtime: DateTime.to_iso8601(offer_endtime)
          }

          notify_alerted_users(type, kw, station, payload)

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

  defp notify_alerted_users(type, power, station, payload) do
    alerts = CargaRapida.AlertAgent.matching_alerts(type, power, station)

    Enum.each(alerts, fn %Alert{user_id: user_id} ->
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
