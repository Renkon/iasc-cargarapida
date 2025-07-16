defmodule CargaRapida.AlertAgent do
  use CargaRapida.BaseAgent, entity_key: :id, timestamp_key: :updated_at

  def put_alert(id, alert_data) do
    put_entry(id, alert_data)
  end

  def delete_alert(id) do
    delete_entry(id)
  end

  def matching_alerts(start_time, type, power, station) do
    get_all()
    |> Enum.map(fn {_id, alert} -> alert end)
    |> Enum.filter(fn alert ->
      DateTime.compare(start_time, alert.start_time) != :lt and
      DateTime.compare(start_time, alert.end_time) != :gt and
      alert.type == type and
      alert.min_power <= power and
      alert.station == station
    end)
  end

  def user_alerts(user_id) do
    get_all()
    |> Enum.map(fn {_id, alert} -> alert end)
    |> Enum.filter(fn alert -> alert.user_id == user_id end)
  end

  def user_alerts_for_router(user_id) do
    user_alerts(user_id)
    |> Enum.map(fn alert ->
      %{
        id: alert.id,
        type: alert.type,
        min_power: alert.min_power,
        start_time: alert.start_time,
        end_time: alert.end_time,
        station: alert.station
      }
    end)
  end
end
