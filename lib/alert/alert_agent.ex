defmodule CargaRapida.AlertAgent do
  use CargaRapida.BaseAgent, entity_key: :id, timestamp_key: :updated_at

  def put_alert(id, alert_data) do
    put_entry(id, alert_data)
  end

  def delete_alert(id) do
    #TODO
  end
end
