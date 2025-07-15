defmodule Alert do
  use GenServer
  defstruct [:id, :start_time, :end_time, :user_id, :type, :min_power, :station]

  def start_link(%Alert{} = alert) do
    GenServer.start_link(__MODULE__, alert, name: via_tuple(alert.id))
  end

  @impl true
  def init(alert) do
    CargaRapida.AlertAgent.put_alert(alert.id, alert)

    now = DateTime.utc_now()
    ms_until_expire =
      case DateTime.diff(alert.end_time, now, :millisecond) do
        diff when diff > 0 -> diff
        _ -> 0
      end

    Process.send_after(self(), :expire, ms_until_expire)
    {:ok, alert}
  end

  @impl true
  def handle_info(:expire, alert) do
    CargaRapida.AlertAgent.delete_entry(alert.id)
    {:stop, :normal, alert}
  end

  @impl true
  def terminate(reason, state) do
    CargaRapida.AlertAgent.delete_alert(state.id)
    reason
  end

  defp via_tuple(id) do
    {:via, Horde.Registry, {CargaRapida.AlertRegistry, id}}
  end
end
