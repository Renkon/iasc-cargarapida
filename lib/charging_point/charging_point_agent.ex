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

  def matching_charging_points(%Alert{start_time: alert_start, end_time: alert_end, type: alert_type, min_power: alert_min_power, station: alert_station}) do
    get_all()
    |> Enum.map(fn {_id, cp} -> cp end)
    |> Enum.filter(fn cp ->
      DateTime.compare(cp.start_time, alert_start) != :lt and
      DateTime.compare(cp.start_time, alert_end) != :gt and
      cp.type == alert_type and
      cp.power >= alert_min_power and
      cp.station == alert_station and
      cp.assigned_user == nil
    end)
  end

  def matching_charging_points_multiple(alerts) do
    alerts
      |> Enum.flat_map(fn alert ->
        CargaRapida.ChargingPointAgent.matching_charging_points(alert)
        |> Enum.map(fn cp ->
          %{
            id: cp.id,
            type: cp.type,
            power: cp.power,
            start_time: cp.start_time,
            station: cp.station,
          }
        end)
    end)
  end

  def get_charging_points_by_user(user_id) do
    get_all()
    |> Enum.map(fn {_id, cp} -> cp end)
    |> Enum.filter(fn cp -> cp.assigned_user == user_id end)
    |> Enum.map(fn cp ->
      %{
        id: cp.id,
        type: cp.type,
        power: cp.power,
        start_time: cp.start_time,
        station: cp.station,
      }
    end)
  end

  def get_all_charging_points do
    get_all()
    |> Enum.map(fn {_id, cp} -> cp end)
    |> Enum.map(fn cp ->
      %{
        id: cp.id,
        type: cp.type,
        power: cp.power,
        start_time: cp.start_time,
        station: cp.station,
        assigned_user: cp.assigned_user
      }
    end)
  end
end
