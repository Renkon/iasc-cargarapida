defmodule CargaRapida.ChargingPointAgent do
  use CargaRapida.BaseAgent, entity_key: :id, timestamp_key: :updated_at

  def put_charging_point(id, charging_point_data) do
    put_entry(id, charging_point_data)
  end

  def get_charging_point(id) do
    get_entry(id)
  end

  def delete_charging_point(id) do
    delete_entry(id)
  end
end
