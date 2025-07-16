defmodule ChargingPoint do
  use GenServer
  defstruct [:id, :start_time, :station, :death_time, :timer, :type, :power, :assigned_user]

  def start_link(%ChargingPoint{id: id} = charging_point) do
    GenServer.start_link(__MODULE__, charging_point, name: via_tuple(id))
  end

  @impl true
  def init(%ChargingPoint{id: id, death_time: death_time} = charging_point) do
    ms_until_expire = ms_until_expire(death_time)

    initial_state =
      case CargaRapida.ChargingPointAgent.get_charging_point(id) do
        nil ->
          CargaRapida.ChargingPointAgent.put_charging_point(id, charging_point)
          charging_point
        saved_charging_point ->
          struct(ChargingPoint, Map.merge(Map.from_struct(charging_point), Map.from_struct(saved_charging_point)))
      end

    timer_ref = Process.send_after(self(), :expire, ms_until_expire)
    updated_state_with_timer = %{initial_state | timer: timer_ref}
    {:ok, updated_state_with_timer}
  end

  @impl true
  def handle_call({:assign_user, username}, _from, %{assigned_user: nil} = state) do
    Process.cancel_timer(state.timer)
    new_death_time = DateTime.add(state.start_time, 30 * 60, :second) # Extend by 30 minutes
    ms_until_expire = ms_until_expire(new_death_time)
    timer_ref = Process.send_after(self(), :expire, ms_until_expire)
    new_state = %{state | assigned_user: username, death_time: new_death_time, timer: timer_ref}
    CargaRapida.ChargingPointAgent.put_charging_point(state.id, new_state)
    CargaRapida.StationManager.notify_all_users_charging_point_assigned(state.id)
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

  defp ms_until_expire(death_time) do
    now = DateTime.utc_now()
    case DateTime.diff(death_time, now, :millisecond) do
      diff when diff > 0 -> diff
      _ -> 0
    end
  end

  defp via_tuple(id) do
    {:via, Horde.Registry, {CargaRapida.ChargingPointRegistry, id}}
  end
end
