defmodule CargaRapida.AlertAgent do
  use CargaRapida.BaseAgent, entity_key: :id, timestamp_key: :updated_at

  def put_alert(id, alert_data) do
    put_entry(id, alert_data)
  end

  def delete_alert(id) do
    delete_entry(id)
  end

  def matching_alerts(type, power, station) do
    get_all()
    |> Enum.map(fn {_id, alert} -> alert end)
    |> Enum.filter(fn alert ->
      alert.type == type and alert.min_power <= power and alert.station == station
    end)
  end

  def get_all() do
    Agent.get(__MODULE__, & &1)
  end
end
