defmodule CargaRapida.AlertSupervisor do
  use CargaRapida.BaseHordeSupervisor

  def create_alerts(user_id, type, min_power, station, start_time_str, end_time_str) do
    {:ok, start_time, _offset} = DateTime.from_iso8601(start_time_str)
    {:ok, end_time, _offset} = DateTime.from_iso8601(end_time_str)

    alert_id = UUID.uuid4()
    alert = %Alert{
      id: alert_id,
      start_time: start_time,
      end_time: end_time,
      user_id: user_id,
      type: String.to_atom(type),
      min_power: min_power,
      station: String.to_atom(station)
    }

    case Horde.DynamicSupervisor.start_child(__MODULE__, {Alert, alert}) do
    {:ok, _pid} -> {:ok, alert_id}
    {:error, reason} -> {:error, reason}
    other -> {:error, other}
  end
  end
end
