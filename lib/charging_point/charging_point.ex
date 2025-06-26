defmodule ChargingPoint do
  use GenServer
  defstruct [:id, :datetime, :station, :offer_endtime, :type, :power, :assigned_user]

  def start_link(%ChargingPoint{id: id} = charging_point) do
    GenServer.start_link(__MODULE__, charging_point, name: via_tuple(id))
  end

  @impl true
  def init(%ChargingPoint{id: id, offer_endtime: offer_endtime} = charging_point) do
    now = DateTime.utc_now()
    ms_until_expire =
      case DateTime.diff(offer_endtime, now, :millisecond) do
        diff when diff > 0 -> diff
        _ -> 0
      end

    initial_state =
      case CargaRapida.ChargingPointAgent.get_charging_point(id) do
        nil ->
          CargaRapida.ChargingPointAgent.put_charging_point(id, charging_point)
          charging_point
        saved_charging_point ->
          struct(ChargingPoint, Map.merge(Map.from_struct(charging_point), Map.from_struct(saved_charging_point)))
      end

    if ms_until_expire == 0 do
      Process.send_after(self(), :expire, 0)
    else
      Process.send_after(self(), :expire, ms_until_expire)
    end

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:assign_user, username}, _from, %{assigned_user: nil} = state) do
    new_state = %{state | assigned_user: username}
    CargaRapida.ChargingPointAgent.put_charging_point(state.id, new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:assign_user, _}, _from, %{assigned_user: existing} = state) do
    {:reply, {:error, :already_reserved, existing}, state}
  end

  @impl true
  def handle_info(:expire, state) do
    {:stop, :normal, state}
  end

  @impl true
  def terminate(reason, state) do
    CargaRapida.ChargingPointAgent.delete_charging_point(state.id)
    reason
  end

  defp via_tuple(id) do
    {:via, Horde.Registry, {CargaRapida.ChargingPointRegistry, id}}
  end
end
