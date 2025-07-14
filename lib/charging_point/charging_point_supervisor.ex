defmodule CargaRapida.ChargingPointSupervisor do
  use CargaRapida.BaseHordeSupervisor

  def create(id, datetime, station, offer_endtime, type, power) do
    charging_point = %ChargingPoint{
      id: id,
      datetime: datetime,
      station: station,
      offer_endtime: offer_endtime,
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
