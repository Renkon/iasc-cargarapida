defmodule CargaRapida.ChargingPointSupervisor do
  use CargaRapida.BaseHordeSupervisor

  def create(id, start_time, station, end_time, type, power) do
    charging_point = %ChargingPoint{
      id: id,
      start_time: start_time,
      station: station,
      end_time: end_time,
      type: type,
      power: power,
      assigned_user: nil
    }

    child_spec = %{
      id: charging_point.id,
      start: {ChargingPoint, :start_link, [charging_point]},
      restart: :transient
    }

    Horde.DynamicSupervisor.start_child(__MODULE__, child_spec)
  end


  def assign_user(charging_point_id, username) do
    case Horde.Registry.lookup(CargaRapida.ChargingPointRegistry, charging_point_id) do
      [{pid, _}] -> GenServer.call(pid, {:assign_user, username})
      _ -> :error
    end
  end
end
