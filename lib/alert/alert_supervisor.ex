defmodule CargaRapida.AlertSupervisor do
  use CargaRapida.BaseHordeSupervisor

  def create_alerts(user_id, type, min_power, station, start_time_str, end_time_str) do
    {:ok, start_time} = DateTime.from_iso8601(start_time_str)
    {:ok, end_time} = DateTime.from_iso8601(end_time_str)

    intervals = time_intervals(start_time, end_time)
    Enum.map(intervals, fn alert_start_time ->
      alert_end_time = DateTime.add(alert_start_time, 1800, :second)
      alert_id = UUID.uuid4()
      alert = %Alert{
        id: alert_id,
        start_time: alert_start_time,
        end_time: alert_end_time,
        user_id: user_id,
        type: type,
        min_power: min_power,
        station: station
      }

      Horde.DynamicSupervisor.start_child(__MODULE__, {Alert, alert})
      alert_id
    end)
  end

  defp time_intervals(start_time, end_time) do
    interval_sec = 1800 # 30 minutes interval
    Stream.iterate(start_time, &DateTime.add(&1, interval_sec, :second))
    |> Stream.take_while(&(DateTime.compare(&1, end_time) != :gt))
    |> Enum.to_list()
  end
end
